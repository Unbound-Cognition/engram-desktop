import Foundation
import Combine

@MainActor
public final class DaemonSupervisor: ObservableObject {
    public static let shared = DaemonSupervisor()

    @Published public private(set) var state: DaemonState = .stopped
    @Published public private(set) var stats: EngramStats? = nil
    @Published public private(set) var recentLogs: [String] = []

    private var process: Process?
    private var outputPipe: Pipe?
    private var healthTimer: AnyCancellable?
    private let client = EngramClient(port: 8420)

    private init() {
        startHealthPolling()
    }

    public func findEngramPath() -> String? {
        let candidates = [
            ("/Users/ari/Ash/engram/.venv/bin/engram" as NSString).expandingTildeInPath,
            ("/Users/ari/.local/bin/engram" as NSString).expandingTildeInPath,
            "/usr/local/bin/engram",
            ("/Users/ari/Library/Python/3.11/bin/engram" as NSString).expandingTildeInPath,
            ("/Users/ari/Library/Python/3.12/bin/engram" as NSString).expandingTildeInPath,
            ("/Users/ari/Library/Python/3.13/bin/engram" as NSString).expandingTildeInPath,
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Check via `which engram`
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        which.arguments = ["engram"]
        let pipe = Pipe()
        which.standardOutput = pipe
        try? which.run()
        which.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !out.isEmpty {
            return out
        }

        return nil
    }

    public func start() {
        guard state != .running && state != .starting else { return }
        state = .starting
        appendLog("[supervisor] starting engram daemon...")

        let proc = Process()
        let pipe = Pipe()
        self.outputPipe = pipe
        proc.standardOutput = pipe
        proc.standardError = pipe

        if let engramBin = findEngramPath() {
            proc.executableURL = URL(fileURLWithPath: engramBin)
            proc.arguments = ["serve", "--web", "--port", "8420"]
        } else {
            // Fallback to python3 module
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            proc.arguments = ["-m", "engram.cli", "serve", "--web", "--port", "8420"]
        }

        proc.terminationHandler = { [weak self] p in
            Task { @MainActor [weak self] in
                self?.appendLog("[supervisor] process exited with code \(p.terminationStatus)")
                self?.state = .stopped
                self?.process = nil
            }
        }

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.appendLog(line)
            }
        }

        do {
            try proc.run()
            self.process = proc
            appendLog("[supervisor] process spawned (PID: \(proc.processIdentifier))")
        } catch {
            state = .error(error.localizedDescription)
            appendLog("[supervisor] failed to spawn process: \(error.localizedDescription)")
        }
    }

    public func stop() {
        appendLog("[supervisor] stopping daemon...")
        healthTimer?.cancel()
        process?.terminate()
        process = nil
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        state = .stopped
        appendLog("[supervisor] daemon stopped.")
    }

    public func restart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.start()
        }
    }

    private func appendLog(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let lines = message.split(separator: "\n").map { "[\(timestamp)] \($0)" }
        recentLogs.append(contentsOf: lines)
        if recentLogs.count > 300 {
            recentLogs.removeFirst(recentLogs.count - 300)
        }
    }

    private func startHealthPolling() {
        healthTimer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.checkHealth()
                }
            }
    }

    public func checkHealth() async {
        do {
            let fetchedStats = try await client.fetchStatus()
            self.stats = fetchedStats
            if self.state != .running {
                self.state = .running
            }
        } catch {
            if self.process == nil && self.state != .starting {
                self.state = .stopped
            }
        }
    }
}
