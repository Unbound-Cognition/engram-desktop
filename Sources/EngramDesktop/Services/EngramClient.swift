import Foundation

public actor EngramClient {
    private let baseURL: URL

    public init(port: Int = 8420) {
        self.baseURL = URL(string: "http://127.0.0.1:\(port)")!
    }

    public func fetchStatus() async throws -> EngramStats {
        let url = baseURL.appendingPathComponent("api/health")
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct HealthPayload: Decodable {
            struct Memories: Decodable {
                let procedural: Int?
                let narrative: Int?
                let episodic: Int?
                let semantic: Int?
                let codebase: Int?
                let total: Int?
            }
            let memories: Memories?
            let entities: Int?
            let relationships: Int?
            let dbSizeMb: Double?
            let version: String?

            enum CodingKeys: String, CodingKey {
                case memories
                case entities
                case relationships
                case dbSizeMb = "db_size_mb"
                case version
            }
        }

        let payload = try JSONDecoder().decode(HealthPayload.self, from: data)
        let totalMemories = payload.memories?.total ?? 0
        let entityCount = payload.entities ?? 0
        let relationshipCount = payload.relationships ?? 0

        var layerCounts: [String: Int] = [:]
        if let mems = payload.memories {
            layerCounts["procedural"] = mems.procedural ?? 0
            layerCounts["episodic"] = mems.episodic ?? 0
            layerCounts["semantic"] = mems.semantic ?? 0
            layerCounts["narrative"] = mems.narrative ?? 0
            layerCounts["codebase"] = mems.codebase ?? 0
        }

        return EngramStats(
            memoryCount: totalMemories,
            entityCount: entityCount,
            relationshipCount: relationshipCount,
            layerCounts: layerCounts,
            port: 8420,
            version: payload.version ?? "0.8.1"
        )
    }

    public func search(query: String, topK: Int = 5) async throws -> [MemorySearchResult] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "top_k", value: String(topK))
        ]

        guard let targetURL = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: targetURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct SearchResponse: Decodable {
            let results: [MemorySearchResult]?
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.results ?? []
    }

    public struct SyncStatus: Decodable, Sendable {
        public let status: String
        public let deviceId: String
        public let sequence: Int
        public let peers: [String]?
        public let hasKey: Bool?

        enum CodingKeys: String, CodingKey {
            case status
            case deviceId = "device_id"
            case sequence
            case peers
            case hasKey = "has_key"
        }
    }

    public struct SyncTriggerResponse: Decodable, Sendable {
        public let status: String
        public let pulled: Int?
        public let pushed: Int?
        public let message: String?
        public let errors: [String]?
    }

    public func fetchSyncStatus() async throws -> SyncStatus {
        let url = baseURL.appendingPathComponent("api/sync/status")
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SyncStatus.self, from: data)
    }

    public func triggerSync() async throws -> SyncTriggerResponse {
        let url = baseURL.appendingPathComponent("api/sync/trigger")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15.0
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SyncTriggerResponse.self, from: data)
    }

    public func updatePeer(peer: String, action: String) async throws -> [String] {
        let url = baseURL.appendingPathComponent("api/sync/peers")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        let payload = ["peer": peer, "action": action]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        struct PeerResp: Decodable { let peers: [String] }
        let decoded = try JSONDecoder().decode(PeerResp.self, from: data)
        return decoded.peers
    }
}
