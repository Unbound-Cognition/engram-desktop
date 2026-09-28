import Foundation

public enum DaemonState: Equatable, Sendable {
    case stopped
    case starting
    case running
    case error(String)

    public var title: String {
        switch self {
        case .stopped: return "Stopped"
        case .starting: return "Starting..."
        case .running: return "Running"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

public struct EngramStats: Codable, Sendable {
    public let memoryCount: Int
    public let entityCount: Int
    public let relationshipCount: Int
    public let layerCounts: [String: Int]
    public let dbPath: String
    public let port: Int
    public let version: String

    public init(
        memoryCount: Int = 0,
        entityCount: Int = 0,
        relationshipCount: Int = 0,
        layerCounts: [String: Int] = [:],
        dbPath: String = "~/.local/share/engram/engram.db",
        port: Int = 8420,
        version: String = "0.8.1"
    ) {
        self.memoryCount = memoryCount
        self.entityCount = entityCount
        self.relationshipCount = relationshipCount
        self.layerCounts = layerCounts
        self.dbPath = dbPath
        self.port = port
        self.version = version
    }

    enum CodingKeys: String, CodingKey {
        case memoryCount = "memory_count"
        case entityCount = "entity_count"
        case relationshipCount = "relationship_count"
        case layerCounts = "layer_counts"
        case dbPath = "db_path"
        case port
        case version
    }
}
