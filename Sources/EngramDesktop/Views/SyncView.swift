import SwiftUI

public struct SyncView: View {
    @State private var deviceId: String = "detecting..."
    @State private var sequence: Int = 0
    @State private var isSyncing: Bool = false
    @State private var statusMessage: String? = nil
    @State private var hasKey: Bool = false

    private let client = EngramClient(port: 8420)
    private let keyPath = ("~/.config/engram/sync.key" as NSString).expandingTildeInPath

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.85, green: 0.60, blue: 0.47))

                VStack(alignment: .leading, spacing: 1) {
                    Text("zero-knowledge sync")
                        .font(.headline)
                    Text("ChaCha20-Poly1305 encrypted multi-device replication")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(spacing: 10) {
                // Key status
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("encryption key")
                            .font(.system(size: 13, weight: .medium))
                        Text(hasKey ? "~/.config/engram/sync.key (configured)" : "missing key — run `engram sync keygen`")
                            .font(.system(size: 11))
                            .foregroundColor(hasKey ? .secondary : .orange)
                    }
                    Spacer()
                    Image(systemName: hasKey ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(hasKey ? .green : .orange)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                // Sequence & Device
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("device id")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(deviceId)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("lamport clock")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("seq #\(sequence)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            if let msg = statusMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Divider()

            HStack {
                Button("refresh status") {
                    refresh()
                }
                .controlSize(.small)

                Spacer()

                Button(action: triggerSync) {
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Label("sync now", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isSyncing || !hasKey)
            }
        }
        .padding(16)
        .frame(width: 440, height: 280)
        .onAppear {
            refresh()
        }
    }

    private func refresh() {
        hasKey = FileManager.default.fileExists(atPath: keyPath)
        Task {
            do {
                let status = try await client.fetchSyncStatus()
                await MainActor.run {
                    self.deviceId = status.deviceId
                    self.sequence = status.sequence
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Daemon sync route not responding: \(error.localizedDescription)"
                }
            }
        }
    }

    private func triggerSync() {
        isSyncing = true
        statusMessage = "triggering peer sync..."

        // Run sync command in background
        DispatchQueue.global().async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            proc.arguments = ["-m", "engram.cli", "sync", "pull"]
            try? proc.run()
            proc.waitUntilExit()

            let pushProc = Process()
            pushProc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            pushProc.arguments = ["-m", "engram.cli", "sync", "push"]
            try? pushProc.run()
            pushProc.waitUntilExit()

            DispatchQueue.main.async {
                self.isSyncing = false
                self.statusMessage = "sync pass completed."
                self.refresh()
            }
        }
    }
}
