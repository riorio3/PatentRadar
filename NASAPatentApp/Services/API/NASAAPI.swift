import Foundation

class NASAAPI {
    static let shared = NASAAPI()

    private let baseURL = "https://technology.nasa.gov/api/api"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    // MARK: - Search Patents
    func searchPatents(query: String, page: Int = 1) async throws -> [Patent] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { throw NASAAPIError.noResults }

        let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedQuery
        let urlString = "\(baseURL)/patent/\(encodedQuery)?page=\(page)"

        guard let url = URL(string: urlString) else {
            throw NASAAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NASAAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw NASAAPIError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(NASAPatentResponse.self, from: data)

        return apiResponse.toPatents()
    }

    // MARK: - Browse All Patents (by category)
    func browsePatents(category: PatentCategory = .all, page: Int = 1) async throws -> [Patent] {
        let query = category == .all ? "" : category.rawValue
        return try await searchPatents(query: query.isEmpty ? "technology" : query, page: page)
    }

    // MARK: - Get Featured/Recent Patents
    func getFeaturedPatents() async throws -> [Patent] {
        // Search across popular categories to get a mix
        let queries = ["aeronautics", "robotics", "sensors", "materials", "propulsion"]
        var allPatents: [Patent] = []

        for query in queries {
            do {
                let patents = try await searchPatents(query: query, page: 1)
                allPatents.append(contentsOf: patents.prefix(3))
            } catch {
                continue // Skip failed queries
            }
        }

        return Array(Set(allPatents)).sorted { $0.title < $1.title }
    }

    // MARK: - Get Patent by ID
    func getPatent(id: String) async throws -> Patent? {
        // The T2 API doesn't have a direct ID lookup, so we search by the case number
        let patents = try await searchPatents(query: id)
        return patents.first { $0.id == id || $0.caseNumber == id }
    }
}

// MARK: - Errors
enum NASAAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .noResults:
            return "No patents found"
        }
    }
}
