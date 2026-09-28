import Foundation

public struct MemorySearchResult: Identifiable, Decodable, Encodable, Sendable {
    public let id: String
    public let content: String
    public let layer: String
    public let score: Double
    public let memoryType: String?
    public let importance: Double?
    public let tags: [String]
    public let factDate: String?

    public init(
        id: String,
        content: String,
        layer: String,
        score: Double,
        memoryType: String? = nil,
        importance: Double? = nil,
        tags: [String] = [],
        factDate: String? = nil
    ) {
        self.id = id
        self.content = content
        self.layer = layer
        self.score = score
        self.memoryType = memoryType
        self.importance = importance
        self.tags = tags
        self.factDate = factDate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case layer
        case score
        case memoryType = "memory_type"
        case importance
        case factDate = "fact_date"
        case metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        self.layer = try container.decode(String.self, forKey: .layer)
        self.score = try container.decodeIfPresent(Double.self, forKey: .score) ?? 0.0
        self.memoryType = try container.decodeIfPresent(String.self, forKey: .memoryType)
        self.importance = try container.decodeIfPresent(Double.self, forKey: .importance)
        self.factDate = try container.decodeIfPresent(String.self, forKey: .factDate)

        struct Meta: Decodable {
            let tags: [String]?
        }
        if let meta = try? container.decodeIfPresent(Meta.self, forKey: .metadata), let metaTags = meta.tags {
            self.tags = metaTags
        } else {
            self.tags = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(layer, forKey: .layer)
        try container.encode(score, forKey: .score)
        try container.encodeIfPresent(importance, forKey: .importance)
        try container.encodeIfPresent(factDate, forKey: .factDate)
    }
}
