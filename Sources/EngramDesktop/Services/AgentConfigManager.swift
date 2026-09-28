import Foundation

public final class AgentConfigManager: Sendable {
    public static let shared = AgentConfigManager()

    private var fileManager: FileManager { FileManager.default }

    private func expandPath(_ path: String) -> String {
        return (path as NSString).expandingTildeInPath
    }

    public func getHarnesses() -> [AgentHarness] {
        var harnesses: [AgentHarness] = []

        // 1. Claude Code
        let claudePath = expandPath("~/.claude.json")
        let claudeInstalled = fileManager.fileExists(atPath: claudePath) || fileManager.fileExists(atPath: expandPath("~/.claude"))
        let claudeWired = isClaudeWired(at: claudePath)
        harnesses.append(AgentHarness(id: "claude_code", name: "Claude Code", configPath: "~/.claude.json", isInstalled: claudeInstalled, isWired: claudeWired))

        // 2. OpenAI Codex CLI
        let codexPath = expandPath("~/.codex/config.json")
        let codexInstalled = fileManager.fileExists(atPath: expandPath("~/.codex"))
        let codexWired = isCodexWired(at: codexPath)
        harnesses.append(AgentHarness(id: "codex", name: "Codex CLI", configPath: "~/.codex/config.json", isInstalled: codexInstalled, isWired: codexWired))

        // 3. Cursor
        let cursorPath = expandPath("~/.cursor/mcp.json")
        let cursorInstalled = fileManager.fileExists(atPath: expandPath("~/.cursor")) || fileManager.fileExists(atPath: expandPath("~/Library/Application Support/Cursor"))
        let cursorWired = isCursorWired(at: cursorPath)
        harnesses.append(AgentHarness(id: "cursor", name: "Cursor IDE", configPath: "~/.cursor/mcp.json", isInstalled: cursorInstalled, isWired: cursorWired))

        // 4. Antigravity / Gemini CLI
        let geminiPath = expandPath("~/.gemini/antigravity-cli/mcp/engram")
        let geminiInstalled = fileManager.fileExists(atPath: expandPath("~/.gemini/antigravity-cli"))
        let geminiWired = fileManager.fileExists(atPath: geminiPath)
        harnesses.append(AgentHarness(id: "antigravity", name: "Antigravity CLI", configPath: "~/.gemini/antigravity-cli/mcp/engram", isInstalled: geminiInstalled, isWired: geminiWired))

        return harnesses
    }

    public func setWiring(for harnessId: String, wired: Bool) throws {
        switch harnessId {
        case "claude_code":
            try toggleClaudeWiring(wired: wired)
        case "codex":
            try toggleCodexWiring(wired: wired)
        case "cursor":
            try toggleCursorWiring(wired: wired)
        case "antigravity":
            try toggleAntigravityWiring(wired: wired)
        default:
            break
        }
    }

    // MARK: - Claude Wiring
    private func isClaudeWired(at path: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mcpServers = json["mcpServers"] as? [String: Any] else {
            return false
        }
        return mcpServers["engram"] != nil
    }

    private func toggleClaudeWiring(wired: Bool) throws {
        let path = expandPath("~/.claude.json")
        let fileURL = URL(fileURLWithPath: path)
        var dict: [String: Any] = [:]

        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict = existing
        }

        var mcpServers = dict["mcpServers"] as? [String: Any] ?? [:]
        if wired {
            mcpServers["engram"] = [
                "command": "engram",
                "args": ["mcp"]
            ]
        } else {
            mcpServers.removeValue(forKey: "engram")
        }
        dict["mcpServers"] = mcpServers

        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: fileURL)
    }

    // MARK: - Codex Wiring
    private func isCodexWired(at path: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mcpServers = json["mcp_servers"] as? [String: Any] ?? json["mcpServers"] as? [String: Any] else {
            return false
        }
        return mcpServers["engram"] != nil
    }

    private func toggleCodexWiring(wired: Bool) throws {
        let path = expandPath("~/.codex/config.json")
        let fileURL = URL(fileURLWithPath: path)
        let parentDir = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        var dict: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict = existing
        }

        let key = dict["mcp_servers"] != nil ? "mcp_servers" : "mcpServers"
        var mcpServers = dict[key] as? [String: Any] ?? [:]
        if wired {
            mcpServers["engram"] = [
                "command": "engram",
                "args": ["mcp"]
            ]
        } else {
            mcpServers.removeValue(forKey: "engram")
        }
        dict[key] = mcpServers

        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: fileURL)
    }

    // MARK: - Cursor Wiring
    private func isCursorWired(at path: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mcpServers = json["mcpServers"] as? [String: Any] else {
            return false
        }
        return mcpServers["engram"] != nil
    }

    private func toggleCursorWiring(wired: Bool) throws {
        let path = expandPath("~/.cursor/mcp.json")
        let fileURL = URL(fileURLWithPath: path)
        let parentDir = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        var dict: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict = existing
        }

        var mcpServers = dict["mcpServers"] as? [String: Any] ?? [:]
        if wired {
            mcpServers["engram"] = [
                "command": "engram",
                "args": ["mcp"]
            ]
        } else {
            mcpServers.removeValue(forKey: "engram")
        }
        dict["mcpServers"] = mcpServers

        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: fileURL)
    }

    // MARK: - Antigravity Wiring
    private func toggleAntigravityWiring(wired: Bool) throws {
        let path = expandPath("~/.gemini/antigravity-cli/mcp/engram")
        if wired {
            if !fileManager.fileExists(atPath: path) {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            }
        } else {
            // keep schemas intact if already present
        }
    }
}
