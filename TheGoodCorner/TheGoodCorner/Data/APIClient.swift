import Foundation

/// Errors surfaced to the UI. Kept small on purpose: the UI only needs
/// to know *that* something failed and whether retrying makes sense.
nonisolated enum APIError: Error, Equatable, Sendable {
    case invalidRequest
    case transport          // no network, timeout, server down
    case invalidResponse
    case httpStatus(Int)
    case decoding
}

/// Thin abstraction over URLSession so API behaviour can be tested without a server.
nonisolated protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

nonisolated extension URLSession: HTTPClient {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

/// Production implementation of `ListingsRepository` backed by the local HTTP API.
nonisolated struct APIClient: ListingsRepository {
    let baseURL: URL
    var http: any HTTPClient = URLSession.shared

    func fetchListings(query: String?) async throws -> [Listing] {
        let feed: ListingFeedDTO = try await get(.listings(query: query))
        return feed.items.map { $0.toDomain(baseURL: baseURL) }
    }

    func fetchCategories() async throws -> [ListingCategory] {
        let categories: [CategoryDTO] = try await get(.categories)
        return categories.map { $0.toDomain() }
    }

    private func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url(relativeTo: baseURL) else { throw APIError.invalidRequest }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await http.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()   // a cancelled request is not a failure to show
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.transport
        }

        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder.makeAPIDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
