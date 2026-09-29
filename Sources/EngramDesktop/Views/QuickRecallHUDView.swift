import SwiftUI

public struct QuickRecallHUDView: View {
    public var onClose: () -> Void

    @State private var query: String = ""
    @State private var selectedLayer: String = "all"
    @State private var results: [MemorySearchResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var copiedId: String? = nil
    @State private var searchDurationMs: Double? = nil
    @State private var searchTask: Task<Void, Never>? = nil

    private let client = EngramClient(port: 8420)
    private let layers = ["all", "procedural", "semantic", "episodic", "codebase"]

    public init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Bar Header
            HStack(spacing: 12) {
                EngramLogoView(size: 22)
                    .frame(width: 22, height: 22)

                TextField("recall context, decisions, procedures, or facts...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .onSubmit {
                        triggerImmediateSearch()
                    }
                    .onChange(of: query) { oldValue, newValue in
                        scheduleDebouncedSearch(newValue)
                    }

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.65)
                } else if !query.isEmpty {
                    Button(action: {
                        query = ""
                        results = []
                        searchDurationMs = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            // Layer Filter Pills
            HStack(spacing: 6) {
                ForEach(layers, id: \.self) { layer in
                    Button(action: {
                        selectedLayer = layer
                        triggerImmediateSearch()
                    }) {
                        Text(layer)
                            .font(.system(size: 11, weight: selectedLayer == layer ? .semibold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                selectedLayer == layer
                                    ? layerColor(layer).opacity(0.18)
                                    : Color(NSColor.controlBackgroundColor)
                            )
                            .foregroundColor(
                                selectedLayer == layer
                                    ? layerColor(layer)
                                    : .secondary
                            )
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Results List
            if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if results.isEmpty {
                VStack(spacing: 8) {
                    Text(query.isEmpty ? "type a query to search memories" : "no matching memories found")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(results) { result in
                            resultCard(result)
                        }
                    }
                    .padding(12)
                }
            }

            Divider()

            // Footer
            HStack {
                HStack(spacing: 8) {
                    Text("\(results.count) results")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let ms = searchDurationMs {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f ms", ms))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("live hybrid recall • esc to close")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 580, height: 420)
        .onExitCommand {
            onClose()
        }
    }

    private func resultCard(_ item: MemorySearchResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Layer badge
                Text(item.layer)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(layerColor(item.layer).opacity(0.15))
                    .foregroundColor(layerColor(item.layer))
                    .cornerRadius(4)

                if let type = item.memoryType {
                    Text(type)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(String(format: "%.0f%%", item.score * 100))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.content, forType: .string)
                    copiedId = item.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedId == item.id { copiedId = nil }
                    }
                }) {
                    Image(systemName: copiedId == item.id ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(copiedId == item.id ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy content to clipboard")
            }

            Text(item.content)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(4)
                .textSelection(.enabled)

            if !item.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(item.tags.prefix(5), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func layerColor(_ layer: String) -> Color {
        switch layer {
        case "procedural": return .purple
        case "semantic": return .blue
        case "episodic": return .green
        case "working": return .orange
        case "codebase": return .indigo
        default: return Color(red: 0.85, green: 0.60, blue: 0.47)
        }
    }

    private func scheduleDebouncedSearch(_ text: String) {
        searchTask?.cancel()
        let clean = text.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else {
            results = []
            searchDurationMs = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms debounce
            if !Task.isCancelled {
                performSearch()
            }
        }
    }

    private func triggerImmediateSearch() {
        searchTask?.cancel()
        performSearch()
    }

    private func performSearch() {
        let clean = query.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let startTime = CFAbsoluteTimeGetCurrent()
        let layerParam = selectedLayer == "all" ? nil : selectedLayer

        Task {
            do {
                let res = try await client.search(query: clean, topK: 8, layer: layerParam)
                let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                await MainActor.run {
                    self.results = res
                    self.searchDurationMs = elapsedMs
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to retrieve memories: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
