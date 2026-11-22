import Foundation

/// Describes one API route and builds its URL.
nonisolated struct Endpoint: Equatable, Sendable {
    let path: String
    var queryItems: [URLQueryItem] = []

    static let categories = Endpoint(path: "categories")

    /// `GET /listings`, optionally filtered by a search term.
    /// A blank query is dropped so the server returns the full feed.
    static func listings(query: String? = nil) -> Endpoint {
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return Endpoint(path: "listings") }
        return Endpoint(path: "listings", queryItems: [URLQueryItem(name: "query", value: trimmed)])
    }

    func url(relativeTo baseURL: URL) -> URL? {
        guard var components = URLComponents(url: baseURL.appending(path: path),
                                             resolvingAgainstBaseURL: false) else {
            return nil
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
            // URLComponents leaves "+" unescaped, but many servers decode it as a space.
            let encodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
            components.percentEncodedQuery = encodedQuery
        }
        return components.url
    }
}
