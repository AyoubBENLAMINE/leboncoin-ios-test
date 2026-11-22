import Foundation
import Combine

/// Drives the listing feed screen: loading, error and retry, category filtering.
/// Contains no UI code, so all of its behaviour is unit-testable.
@MainActor
final class ListingListViewModel: ObservableObject {

    enum State: Equatable {
        case idle       // nothing requested yet
        case loading    // first load in progress (full-screen spinner)
        case loaded     // content available (may be empty)
        case failed     // first load failed (full-screen error with retry)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var categories: [ListingCategory] = []
    @Published var selectedCategoryID: ListingCategory.ID?

    private var allListings: [Listing] = []
    private var categoryNames: [ListingCategory.ID: String] = [:]
    private let repository: any ListingsRepository

    init(repository: any ListingsRepository) {
        self.repository = repository
    }

    /// Listings to display. The API order (urgent first, then newest) is preserved:
    /// we only filter, never re-sort.
    var visibleListings: [Listing] {
        guard let selectedCategoryID else { return allListings }
        return allListings.filter { $0.categoryID == selectedCategoryID }
    }

    var selectedCategoryName: String? {
        selectedCategoryID.flatMap { categoryNames[$0] }
    }

    /// Category name of a listing, or nil if the API returned an unknown category id.
    func categoryName(for listing: Listing) -> String? {
        categoryNames[listing.categoryID]
    }

    /// First load, triggered when the screen appears. No-op once loading has started.
    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    /// Loads or reloads listings and categories in parallel.
    /// During a pull-to-refresh, the current content stays on screen and is kept if the refresh fails.
    func load() async {
        let hadContent = state == .loaded
        if !hadContent { state = .loading }

        do {
            async let listings = repository.fetchListings(query: nil)
            async let categories = repository.fetchCategories()
            let (fetchedListings, fetchedCategories) = try await (listings, categories)

            allListings = fetchedListings
            self.categories = fetchedCategories.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            categoryNames = Dictionary(fetchedCategories.map { ($0.id, $0.name) },
                                       uniquingKeysWith: { first, _ in first })
            state = .loaded
        } catch is CancellationError {
            if !hadContent { state = .idle }   // screen left: allow a fresh load later
        } catch {
            if !hadContent { state = .failed }
        }
    }
}
