import SwiftUI

public struct DaemonLogView: View {
    @ObservedObject var supervisor = DaemonSupervisor.shared
    @State private var copied: Bool = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("daemon logs")
                    .font(.headline)

                Spacer()

                Button(action: {
                    let fullLog = supervisor.recentLogs.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(fullLog, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                }) {
                    Label(copied ? "copied" : "copy logs", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        if supervisor.recentLogs.isEmpty {
                            Text("no daemon logs recorded yet.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(8)
                        } else {
                            ForEach(Array(supervisor.recentLogs.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                            }
                        }
                    }
                    .padding(8)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .onChange(of: supervisor.recentLogs.count) { _, newCount in
                    if newCount > 0 {
                        withAnimation {
                            proxy.scrollTo(newCount - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 520, height: 350)
    }
}
