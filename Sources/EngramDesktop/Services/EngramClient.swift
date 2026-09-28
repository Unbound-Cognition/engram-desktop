import Foundation

public actor EngramClient {
    private let baseURL: URL

    public init(port: Int = 8420) {
        self.baseURL = URL(string: "http://127.0.0.1:\(port)")!
    }

    public func fetchStatus() async throws -> EngramStats {
        let url = baseURL.appendingPathComponent("api/status")
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Try decoding as full stats, or fallback to status envelope
        if let stats = try? JSONDecoder().decode(EngramStats.self, from: data) {
            return stats
        }

        struct StatusEnvelope: Decodable {
            let status: String?
            let memoryCount: Int?
            let entityCount: Int?
            let relationshipCount: Int?
            let version: String?

            enum CodingKeys: String, CodingKey {
                case status
                case memoryCount = "memory_count"
                case entityCount = "entity_count"
                case relationshipCount = "relationship_count"
                case version
            }
        }

        let envelope = try JSONDecoder().decode(StatusEnvelope.self, from: data)
        return EngramStats(
            memoryCount: envelope.memoryCount ?? 0,
            entityCount: envelope.entityCount ?? 0,
            relationshipCount: envelope.relationshipCount ?? 0,
            layerCounts: [:],
            port: 8420,
            version: envelope.version ?? "0.8.1"
        )
    }

    public func search(query: String, topK: Int = 5) async throws -> [MemorySearchResult] {
        let url = baseURL.appendingPathComponent("api/search")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0

        let payload: [String: Any] = [
            "query": query,
            "top_k": topK
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct SearchResponse: Decodable {
            let status: String
            let results: [MemorySearchResult]?
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.results ?? []
    }
}
