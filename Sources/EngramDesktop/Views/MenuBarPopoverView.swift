import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @ObservedObject var supervisor = DaemonSupervisor.shared
    public var onOpenHUD: () -> Void
    public var onOpenWiring: () -> Void
    public var onOpenLogs: () -> Void

    public init(
        onOpenHUD: @escaping () -> Void = {},
        onOpenWiring: @escaping () -> Void = {},
        onOpenLogs: @escaping () -> Void = {}
    ) {
        self.onOpenHUD = onOpenHUD
        self.onOpenWiring = onOpenWiring
        self.onOpenLogs = onOpenLogs
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status Header
            HStack(spacing: 10) {
                EngramLogoView(size: 24)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 7, height: 7)

                        Text(supervisor.state.title)
                            .font(.system(size: 13, weight: .semibold))
                    }

                    if let stats = supervisor.stats {
                        Text("\(stats.memoryCount) memories • \(stats.entityCount) entities")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("127.0.0.1:8420")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if supervisor.state == .running {
                    Button("restart") {
                        supervisor.restart()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else if supervisor.state == .starting {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Button("start") {
                        supervisor.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Divider()

            // Quick Actions
            VStack(spacing: 6) {
                Button(action: onOpenHUD) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("quick recall")
                        Spacer()
                        Text("⌘⇧M")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Button(action: {
                    if let url = URL(string: "http://127.0.0.1:8420") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("open web dashboard")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }

            Divider()

            // Secondary Utilities
            VStack(spacing: 6) {
                Button(action: onOpenWiring) {
                    HStack {
                        Image(systemName: "puzzlepiece.extension")
                        Text("agent integrations")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Button(action: onOpenLogs) {
                    HStack {
                        Image(systemName: "terminal")
                        Text("daemon logs")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }

            Divider()

            // Quit
            HStack {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("quit engram")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                if let stats = supervisor.stats {
                    Text("v\(stats.version)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(width: 260)
    }

    private var statusColor: Color {
        switch supervisor.state {
        case .running: return .green
        case .starting: return .yellow
        case .stopped: return .secondary
        case .error: return .red
        }
    }
}
