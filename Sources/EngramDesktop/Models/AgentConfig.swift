import Foundation

public struct AgentHarness: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let configPath: String
    public var isInstalled: Bool
    public var isWired: Bool

    public init(id: String, name: String, configPath: String, isInstalled: Bool = false, isWired: Bool = false) {
        self.id = id
        self.name = name
        self.configPath = configPath
        self.isInstalled = isInstalled
        self.isWired = isWired
    }
}
