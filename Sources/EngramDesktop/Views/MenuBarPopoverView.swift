import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @ObservedObject var supervisor = DaemonSupervisor.shared
    public var onOpenHUD: () -> Void
    public var onOpenWiring: () -> Void
    public var onOpenSync: () -> Void
    public var onOpenLogs: () -> Void

    public init(
        onOpenHUD: @escaping () -> Void = {},
        onOpenWiring: @escaping () -> Void = {},
        onOpenSync: @escaping () -> Void = {},
        onOpenLogs: @escaping () -> Void = {}
    ) {
        self.onOpenHUD = onOpenHUD
        self.onOpenWiring = onOpenWiring
        self.onOpenSync = onOpenSync
        self.onOpenLogs = onOpenLogs
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status Header
            HStack(spacing: 10) {
                EngramLogoView(size: 24)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
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
                            .lineLimit(1)
                    } else {
                        Text("127.0.0.1:8420")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

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
            VStack(spacing: 2) {
                menuRow(
                    icon: "magnifyingglass",
                    title: "quick recall",
                    shortcut: "⌘⇧M",
                    action: onOpenHUD
                )

                menuRow(
                    icon: "safari",
                    title: "open web dashboard",
                    action: {
                        if let url = URL(string: "http://127.0.0.1:8420") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
            }

            Divider()

            // Secondary Utilities
            VStack(spacing: 2) {
                menuRow(
                    icon: "puzzlepiece.extension",
                    title: "agent integrations",
                    action: onOpenWiring
                )

                menuRow(
                    icon: "lock.shield",
                    title: "zero-knowledge sync",
                    action: onOpenSync
                )

                menuRow(
                    icon: "terminal",
                    title: "daemon logs",
                    action: onOpenLogs
                )
            }

            Divider()

            // Footer / Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                        .frame(width: 18, height: 18, alignment: .center)
                        .foregroundColor(.secondary)

                    Text("quit engram")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    if let stats = supervisor.stats {
                        Text("v\(stats.version)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 290)
    }

    private func menuRow(
        icon: String,
        title: String,
        shortcut: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 18, height: 18, alignment: .center)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Spacer()

                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
