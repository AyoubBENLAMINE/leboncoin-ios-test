import SwiftUI

@main
struct TheGoodCornerApp: App {
    var body: some Scene {
        WindowGroup {
            ListingListView(viewModel: ListingListViewModel(
                repository: APIClient(baseURL: AppConfiguration.apiBaseURL)
            ))
        }
    }
}

nonisolated enum AppConfiguration {
    /// Local API server (works in the Simulator). Can be overridden with the
    /// API_BASE_URL environment variable, e.g. to point a physical device at the Mac's IP.
    static var apiBaseURL: URL {
        if let value = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: value) {
            return url
        }
        return URL(string: "http://localhost:8080")!
    }
}
