import XCTest
@testable import TheGoodCorner

/// Returns a canned HTTP response, so API behaviour is tested without a server.
private struct StubHTTPClient: HTTPClient {
    let statusCode: Int
    let body: String

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode,
                                       httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }
}

final class APIClientTests: XCTestCase {

    private let baseURL = URL(string: "http://localhost:8080")!

    // Request building: blank queries are dropped, special characters are escaped.
    func test_listingsEndpoint_buildsExpectedURLs() {
        XCTAssertEqual(Endpoint.listings().url(relativeTo: baseURL)?.absoluteString,
                       "http://localhost:8080/listings")
        XCTAssertEqual(Endpoint.listings(query: "   ").url(relativeTo: baseURL)?.absoluteString,
                       "http://localhost:8080/listings")
        XCTAssertEqual(Endpoint.listings(query: " vélo c++ ").url(relativeTo: baseURL)?.absoluteString,
                       "http://localhost:8080/listings?query=v%C3%A9lo%20c%2B%2B")
    }

    // A non-2xx status becomes a typed error instead of a decoding failure.
    func test_fetchCategories_onServerError_throwsHTTPStatus() async {
        let client = APIClient(baseURL: baseURL,
                               http: StubHTTPClient(statusCode: 500, body: "oops"))
        do {
            _ = try await client.fetchCategories()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .httpStatus(500))
        }
    }

    // A 200 with an unexpected body is reported as a decoding error.
    func test_fetchListings_onMalformedJSON_throwsDecoding() async {
        let client = APIClient(baseURL: baseURL,
                               http: StubHTTPClient(statusCode: 200, body: "{ \"unexpected\": true }"))
        do {
            _ = try await client.fetchListings(query: nil)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .decoding)
        }
    }
}
