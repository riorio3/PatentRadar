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

    // MARK: - Fetch Extended Patent Details
    /// Fetches the full patent detail page and extracts additional information
    /// including benefits, applications, multiple images, and patent numbers
    func fetchPatentDetails(for patent: Patent) async throws -> Patent {
        let caseNumber = patent.caseNumber
        guard !caseNumber.isEmpty else { return patent }

        let urlString = "https://technology.nasa.gov/patent/\(caseNumber)"
        guard let url = URL(string: urlString) else { return patent }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            return patent
        }

        // Parse the HTML to extract additional details
        var updatedPatent = patent
        updatedPatent.benefits = parseListItems(from: html, sectionId: "benefits")
        updatedPatent.applications = parseApplications(from: html)
        updatedPatent.patentNumbers = parsePatentNumbers(from: html)
        updatedPatent.caseNumbers = parseCaseNumbers(from: html)
        updatedPatent.imageURLs = parseImageURLs(from: html, caseNumber: caseNumber)
        updatedPatent.relatedTechnologies = parseRelatedTechnologies(from: html)
        updatedPatent.detailLoaded = true

        return updatedPatent
    }

    // MARK: - HTML Parsing Helpers

    private func parseListItems(from html: String, sectionId: String) -> [String]? {
        // Look for benefits section - typically in a list after "Benefits" heading
        let patterns = [
            // Pattern for list items in benefits section
            "(?i)benefits[^<]*</h[1-6]>\\s*<ul[^>]*>(.*?)</ul>",
            "(?i)<div[^>]*benefits[^>]*>.*?<ul[^>]*>(.*?)</ul>",
            "(?i)benefits.*?<li[^>]*>(.*?)</li>"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let listContent = String(html[range])
                return extractListItems(from: listContent)
            }
        }

        // Fallback: look for any list items near "Benefits" text
        if let benefitsRange = html.range(of: "Benefits", options: .caseInsensitive) {
            let searchStart = benefitsRange.lowerBound
            let searchEnd = html.index(searchStart, offsetBy: min(3000, html.distance(from: searchStart, to: html.endIndex)))
            let searchArea = String(html[searchStart..<searchEnd])
            let items = extractListItems(from: searchArea)
            if !items.isEmpty {
                return items
            }
        }

        return nil
    }

    private func extractListItems(from html: String) -> [String] {
        var items: [String] = []
        let liPattern = "<li[^>]*>(.*?)</li>"

        if let regex = try? NSRegularExpression(pattern: liPattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) {
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if let range = Range(match.range(at: 1), in: html) {
                    let item = String(html[range])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !item.isEmpty {
                        items.append(item)
                    }
                }
            }
        }
        return items
    }

    private func parseApplications(from html: String) -> [PatentApplication]? {
        // Look for Applications section
        guard let appsRange = html.range(of: "Applications", options: .caseInsensitive) else {
            return nil
        }

        let searchStart = appsRange.lowerBound
        let searchEnd = html.index(searchStart, offsetBy: min(5000, html.distance(from: searchStart, to: html.endIndex)))
        let searchArea = String(html[searchStart..<searchEnd])

        var applications: [PatentApplication] = []

        // Pattern for application items with domain and description
        // Format often: "Domain: Description" or just list items
        let items = extractListItems(from: searchArea)

        for item in items {
            if item.contains(":") {
                let parts = item.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    applications.append(PatentApplication(
                        domain: String(parts[0]).trimmingCharacters(in: .whitespaces),
                        description: String(parts[1]).trimmingCharacters(in: .whitespaces)
                    ))
                } else {
                    applications.append(PatentApplication(domain: item, description: ""))
                }
            } else {
                applications.append(PatentApplication(domain: item, description: ""))
            }
        }

        return applications.isEmpty ? nil : applications
    }

    private func parsePatentNumbers(from html: String) -> [String]? {
        var patentNumbers: [String] = []

        // Pattern for USPTO patent numbers (typically 7-8 digits, may have commas)
        let patterns = [
            "(?i)patent[^0-9]*([0-9]{1,3}(?:,?[0-9]{3})+)",
            "US([0-9]{7,8})",
            ">([0-9]{1,3},?[0-9]{3},?[0-9]{3})<"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: html) {
                        let number = String(html[range])
                            .replacingOccurrences(of: ",", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        if number.count >= 7 && number.count <= 10 && !patentNumbers.contains(number) {
                            patentNumbers.append(number)
                        }
                    }
                }
            }
        }

        return patentNumbers.isEmpty ? nil : patentNumbers
    }

    private func parseCaseNumbers(from html: String) -> [String]? {
        var caseNumbers: [String] = []

        // NASA case number pattern: ABC-12345-1 or ABC-TOPS-123
        let pattern = "[A-Z]{2,4}-(?:TOPS-)?[0-9]+(?:-[0-9A-Z]+)?"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if let range = Range(match.range, in: html) {
                    let caseNum = String(html[range])
                    if !caseNumbers.contains(caseNum) && caseNum.count <= 20 {
                        caseNumbers.append(caseNum)
                    }
                }
            }
        }

        // Limit to reasonable number of unique case numbers
        let uniqueCases = Array(Set(caseNumbers)).prefix(10)
        return uniqueCases.isEmpty ? nil : Array(uniqueCases)
    }

    private func parseImageURLs(from html: String, caseNumber: String) -> [String]? {
        var imageURLs: [String] = []

        // Look for image URLs in the t2media directory
        let patterns = [
            "https://technology\\.nasa\\.gov/t2media/tops/img/[^\"'\\s]+\\.(jpg|jpeg|png|gif)",
            "/t2media/tops/img/[^\"'\\s]+\\.(jpg|jpeg|png|gif)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                for match in matches {
                    if let range = Range(match.range, in: html) {
                        var url = String(html[range])
                        // Ensure full URL
                        if url.hasPrefix("/") {
                            url = "https://technology.nasa.gov" + url
                        }
                        if !imageURLs.contains(url) {
                            imageURLs.append(url)
                        }
                    }
                }
            }
        }

        return imageURLs.isEmpty ? nil : imageURLs
    }

    private func parseRelatedTechnologies(from html: String) -> [RelatedTechnology]? {
        var related: [RelatedTechnology] = []

        // Look for related/similar technologies section
        guard let relatedRange = html.range(of: "Related", options: .caseInsensitive) ??
              html.range(of: "Similar", options: .caseInsensitive) else {
            return nil
        }

        let searchStart = relatedRange.lowerBound
        let searchEnd = html.index(searchStart, offsetBy: min(5000, html.distance(from: searchStart, to: html.endIndex)))
        let searchArea = String(html[searchStart..<searchEnd])

        // Pattern for linked technologies
        let pattern = "href=[\"']/patent/([A-Z]{2,4}-TOPS-[0-9]+)[\"'][^>]*>([^<]+)"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: searchArea, options: [], range: NSRange(searchArea.startIndex..., in: searchArea))
            for match in matches.prefix(6) {
                if let caseRange = Range(match.range(at: 1), in: searchArea),
                   let titleRange = Range(match.range(at: 2), in: searchArea) {
                    let caseNum = String(searchArea[caseRange])
                    let title = String(searchArea[titleRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !title.isEmpty {
                        related.append(RelatedTechnology(
                            id: caseNum,
                            title: title,
                            caseNumber: caseNum
                        ))
                    }
                }
            }
        }

        return related.isEmpty ? nil : related
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
