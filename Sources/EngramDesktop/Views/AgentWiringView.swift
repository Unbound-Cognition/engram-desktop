import SwiftUI

public struct AgentWiringView: View {
    @State private var harnesses: [AgentHarness] = []
    @State private var statusMessage: String? = nil

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("agent integrations")
                .font(.headline)

            Text("one-click mcp wiring for local agent harnesses. writes server configuration directly to client config files.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            VStack(spacing: 10) {
                ForEach(harnesses) { harness in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(harness.name)
                                    .font(.system(size: 13, weight: .medium))

                                if harness.isInstalled {
                                    Text("installed")
                                        .font(.system(size: 9))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(3)
                                } else {
                                    Text("not detected")
                                        .font(.system(size: 9))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.15))
                                        .foregroundColor(.secondary)
                                        .cornerRadius(3)
                                }
                            }

                            Text(harness.configPath)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { harness.isWired },
                            set: { newValue in
                                toggleWiring(for: harness, wired: newValue)
                            }
                        ))
                        .toggleStyle(.switch)
                        .disabled(!harness.isInstalled)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
            }

            if let message = statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .frame(width: 440, height: 320)
        .onAppear {
            refresh()
        }
    }

    private func refresh() {
        harnesses = AgentConfigManager.shared.getHarnesses()
    }

    private func toggleWiring(for harness: AgentHarness, wired: Bool) {
        do {
            try AgentConfigManager.shared.setWiring(for: harness.id, wired: wired)
            statusMessage = "\(harness.name) \(wired ? "wired successfully" : "unwired")."
            refresh()
        } catch {
            statusMessage = "Error updating \(harness.name): \(error.localizedDescription)"
        }
    }
}
