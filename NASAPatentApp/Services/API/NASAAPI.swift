import Foundation

class NASAAPI {
    static let shared = NASAAPI()

    private let baseURL = "https://technology.nasa.gov"
    private let session: URLSession

    // Cache for "All" patents
    private var cachedAllPatents: [Patent]?
    private var cacheTime: Date?
    private let cacheValiditySeconds: TimeInterval = 300 // 5 minutes

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    // MARK: - Browse Patents by Category
    func browsePatents(category: PatentCategory = .all) async throws -> [Patent] {
        let slug: String
        switch category {
        case .all:
            return try await fetchAllCategories()
        case .aeronautics:
            slug = "aerospace"
        case .communications:
            slug = "communications"
        case .electronics:
            slug = "electrical%20and%20electronics"
        case .environment:
            slug = "environment"
        case .health:
            slug = "health%20medicine%20and%20biotechnology"
        case .information:
            slug = "information%20technology%20and%20software"
        case .instrumentation:
            slug = "instrumentation"
        case .manufacturing:
            slug = "manufacturing"
        case .materials:
            slug = "materials%20and%20coatings"
        case .mechanical:
            slug = "mechanical%20and%20fluid%20systems"
        case .optics:
            slug = "optics"
        case .power:
            slug = "power%20generation%20and%20storage"
        case .propulsion:
            slug = "propulsion"
        case .robotics:
            slug = "robotics%20automation%20and%20control"
        case .sensors:
            slug = "sensors"
        }

        return await fetchCategory(slug: slug)
    }

    // MARK: - Fetch Single Category
    private func fetchCategory(slug: String) async -> [Patent] {
        let urlString = "\(baseURL)/searchosapicat/multi/aw/patent/\(slug)/1/200/"

        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return [] }

            let results = try JSONDecoder().decode([ElasticSearchResult].self, from: data)

            return results.compactMap { result -> Patent? in
                guard let title = result.source.title, !title.isEmpty else { return nil }

                let imageURL: String?
                if let img = result.source.img1, !img.isEmpty {
                    imageURL = img.hasPrefix("http") ? img : "\(baseURL)\(img)"
                } else {
                    imageURL = nil
                }

                var desc = result.source.abstract ?? ""
                if let tech = result.source.techDesc, !tech.isEmpty, !desc.contains(tech.prefix(50)) {
                    desc += desc.isEmpty ? tech : "\n\n\(tech)"
                }

                return Patent(
                    id: result.id,
                    title: title,
                    description: desc,
                    category: result.source.category ?? "General",
                    caseNumber: result.source.clientRecordId ?? result.id,
                    patentNumber: result.source.patentNumber,
                    imageURL: imageURL,
                    center: result.source.center,
                    trl: result.source.trl
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Fetch All Categories Combined
    private func fetchAllCategories() async throws -> [Patent] {
        // Return cached data if valid
        if let cached = cachedAllPatents,
           let time = cacheTime,
           Date().timeIntervalSince(time) < cacheValiditySeconds {
            return cached
        }

        let slugs = [
            "aerospace",
            "communications",
            "electrical%20and%20electronics",
            "environment",
            "health%20medicine%20and%20biotechnology",
            "information%20technology%20and%20software",
            "instrumentation",
            "manufacturing",
            "materials%20and%20coatings",
            "mechanical%20and%20fluid%20systems",
            "optics",
            "power%20generation%20and%20storage",
            "propulsion",
            "robotics%20automation%20and%20control",
            "sensors"
        ]

        var allPatents: [String: Patent] = [:]

        await withTaskGroup(of: [Patent].self) { group in
            for slug in slugs {
                group.addTask {
                    await self.fetchCategory(slug: slug)
                }
            }

            for await patents in group {
                for patent in patents {
                    if allPatents[patent.id] == nil {
                        allPatents[patent.id] = patent
                    }
                }
            }
        }

        let patents = Array(allPatents.values).sorted { $0.title < $1.title }

        // Cache results
        cachedAllPatents = patents
        cacheTime = Date()

        return patents
    }

    // MARK: - Search Patents
    func searchPatents(query: String, page: Int = 1) async throws -> [Patent] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { throw NASAAPIError.noResults }

        let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedQuery
        let urlString = "\(baseURL)/api/api/patent/\(encodedQuery)?page=\(page)"

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

        let apiResponse = try JSONDecoder().decode(NASAPatentResponse.self, from: data)
        return apiResponse.toPatents()
    }

    // MARK: - Get Patent Detail
    func getPatentDetail(caseNumber: String) async throws -> PatentDetail {
        let urlString = "\(baseURL)/patent/\(caseNumber)"
        guard let url = URL(string: urlString) else {
            throw NASAAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NASAAPIError.invalidResponse
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw NASAAPIError.invalidResponse
        }

        return parsePatentDetail(html: html, caseNumber: caseNumber)
    }

    // MARK: - HTML Parser
    private func parsePatentDetail(html: String, caseNumber: String) -> PatentDetail {
        let title = extractMatch(from: html, pattern: "<h1[^>]*>([^<]+)</h1>") ?? caseNumber

        var abstract = extractMatch(from: html, pattern: "<div class=\"abstract body-text\">(.*?)</div>") ?? ""
        abstract = cleanHTML(abstract)

        var techDesc = extractMatch(from: html, pattern: "<div class=\"tech_desc body-text\">(.*?)</div>") ?? ""
        techDesc = cleanHTML(techDesc)

        var descriptionParts: [String] = []
        if !abstract.isEmpty { descriptionParts.append(abstract) }
        if !techDesc.isEmpty && techDesc != abstract { descriptionParts.append(techDesc) }
        let description = descriptionParts.joined(separator: "\n\n")

        let benefitsSection = extractMatch(from: html, pattern: "<div class=\"benefits\">(.*?)</div>\\s*(?:</div>|<hr)") ?? ""
        let benefits = extractListItems(from: benefitsSection)

        let appsSection = extractMatch(from: html, pattern: "<div class=\"applications\">(.*?)</div>\\s*(?:</div>|<hr)") ?? ""
        let applications = extractListItems(from: appsSection)

        let images = extractMatches(from: html, pattern: "src=\"(https://technology\\.nasa\\.gov/t2media/tops/img/[^\"]+)\"")

        // YouTube videos only
        var videos: [String] = []
        let youtubeEmbedIDs = extractMatches(from: html, pattern: "src=[\"']https?://(?:www\\.)?youtube\\.com/embed/([^\"'?]+)")
        let youtubeWatchIDs = extractMatches(from: html, pattern: "href=[\"']https?://(?:www\\.)?youtube\\.com/watch\\?v=([^\"'&]+)")
        for videoID in Set(youtubeEmbedIDs + youtubeWatchIDs) {
            videos.append("https://www.youtube.com/watch?v=\(videoID)")
        }

        let patentNumbers = extractMatches(from: html, pattern: ">([0-9,D][0-9,]+)</a>")
            .map { $0.replacingOccurrences(of: ",", with: "") }
            .filter { $0.count >= 6 }

        let relatedSection = extractMatch(from: html, pattern: "<div class=\"related\">(.*?)</div>") ?? ""
        let related = extractMatches(from: relatedSection, pattern: "href=\"/patent/([^\"]+)\"")

        return PatentDetail(
            id: caseNumber,
            caseNumber: caseNumber,
            title: title,
            fullDescription: description,
            benefits: benefits,
            applications: applications,
            images: images,
            videos: videos,
            patentNumbers: patentNumbers,
            relatedTechnologies: related
        )
    }

    // MARK: - Regex Helpers
    private func extractMatch(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private func extractMatches(from text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    private func extractListItems(from text: String) -> [String] {
        let items = extractMatches(from: text, pattern: "<li>([^<]+)</li>")
        return items.map { cleanHTML($0) }.filter { !$0.isEmpty }
    }

    private func cleanHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors
enum NASAAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "Server error: \(code)"
        case .noResults: return "No patents found"
        }
    }
}
