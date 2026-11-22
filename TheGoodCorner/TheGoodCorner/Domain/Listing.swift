import Foundation

/// A classified ad, as used by the app.
/// Clean domain model: no JSON naming, no server-relative paths.
struct Listing: Identifiable, Hashable, Sendable {
    let id: Int
    let categoryID: Int
    let title: String
    let description: String
    let price: Double
    let creationDate: Date
    let isUrgent: Bool
    let images: ListingImages
}

/// Image URLs of a listing. Each one is optional:
/// the API may return no image at all, or `null` for a given size.
struct ListingImages: Hashable, Sendable {
    let small: URL?
    let thumb: URL?

    static let none = ListingImages(small: nil, thumb: nil)
}
