import SwiftUI

public struct SyncView: View {
    @State private var deviceId: String = "detecting..."
    @State private var sequence: Int = 0
    @State private var peers: [String] = []
    @State private var newPeerURL: String = ""
    @State private var isSyncing: Bool = false
    @State private var statusMessage: String? = nil
    @State private var hasKey: Bool = false
    @State private var isAddingPeer: Bool = false

    private let client = EngramClient(port: 8420)
    private let keyPath = ("~/.config/engram/sync.key" as NSString).expandingTildeInPath

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            VStack(spacing: 8) {
                // Key status
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("encryption key")
                            .font(.system(size: 12, weight: .medium))
                        Text(hasKey ? "~/.config/engram/sync.key (configured)" : "missing key — run `engram sync keygen`")
                            .font(.system(size: 11))
                            .foregroundColor(hasKey ? .secondary : .orange)
                    }
                    Spacer()
                    Image(systemName: hasKey ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(hasKey ? .green : .orange)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                // Sequence & Device
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("device id")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(deviceId)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("lamport clock")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("seq #\(sequence)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Peers Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("sync peers (\(peers.count))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }

                if peers.isEmpty {
                    Text("no peers configured — pull/push over local network or relay")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 4) {
                        ForEach(peers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "network")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(peer)
                                    .font(.system(size: 11, design: .monospaced))
                                Spacer()
                                Button(action: { removePeer(peer) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                        }
                    }
                }

                // Add peer input
                HStack(spacing: 6) {
                    TextField("http://my-peer:8420", text: $newPeerURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                        .onSubmit {
                            addPeer()
                        }

                    Button("add") {
                        addPeer()
                    }
                    .controlSize(.small)
                    .disabled(newPeerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingPeer)
                }
            }

            if let msg = statusMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Divider()

            HStack {
                Button("refresh") {
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
        .frame(width: 440, height: 380)
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
                    self.peers = status.peers ?? []
                    if let hk = status.hasKey {
                        self.hasKey = hk
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Daemon sync route not responding: \(error.localizedDescription)"
                }
            }
        }
    }

    private func addPeer() {
        let clean = newPeerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        isAddingPeer = true

        Task {
            do {
                let updated = try await client.updatePeer(peer: clean, action: "add")
                await MainActor.run {
                    self.peers = updated
                    self.newPeerURL = ""
                    self.isAddingPeer = false
                    self.statusMessage = "peer added."
                }
            } catch {
                await MainActor.run {
                    self.isAddingPeer = false
                    self.statusMessage = "failed to add peer: \(error.localizedDescription)"
                }
            }
        }
    }

    private func removePeer(_ peer: String) {
        Task {
            do {
                let updated = try await client.updatePeer(peer: peer, action: "remove")
                await MainActor.run {
                    self.peers = updated
                    self.statusMessage = "peer removed."
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "failed to remove peer: \(error.localizedDescription)"
                }
            }
        }
    }

    private func triggerSync() {
        isSyncing = true
        statusMessage = "triggering replication pass..."

        Task {
            do {
                let res = try await client.triggerSync()
                await MainActor.run {
                    self.isSyncing = false
                    if let errs = res.errors, !errs.isEmpty {
                        self.statusMessage = "sync pass finished with errors: \(errs.joined(separator: ", "))"
                    } else if let msg = res.message {
                        self.statusMessage = msg
                    } else {
                        let pulled = res.pulled ?? 0
                        let pushed = res.pushed ?? 0
                        self.statusMessage = "sync pass completed: \(pulled) pulled, \(pushed) pushed."
                    }
                    self.refresh()
                }
            } catch {
                await MainActor.run {
                    self.isSyncing = false
                    self.statusMessage = "sync failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
