import Foundation

/// What the UI layer needs from the data layer.
/// The view model depends on this abstraction only, so it can be tested with a fake.
nonisolated protocol ListingsRepository: Sendable {
    /// Returns listings in API display order (urgent first, then newest).
    /// - Parameter query: optional search term; nil or blank returns the full feed.
    func fetchListings(query: String?) async throws -> [Listing]
    func fetchCategories() async throws -> [ListingCategory]
}
