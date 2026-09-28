import Foundation

public struct MemorySearchResult: Identifiable, Codable, Sendable {
    public let id: String
    public let content: String
    public let layer: String
    public let score: Double
    public let memoryType: String?
    public let tags: [String]
    public let factDate: String?

    public init(
        id: String,
        content: String,
        layer: String,
        score: Double,
        memoryType: String? = nil,
        tags: [String] = [],
        factDate: String? = nil
    ) {
        self.id = id
        self.content = content
        self.layer = layer
        self.score = score
        self.memoryType = memoryType
        self.tags = tags
        self.factDate = factDate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case layer
        case score
        case memoryType = "memory_type"
        case tags
        case factDate = "fact_date"
    }
}
