import Foundation

/// Raw JSON shape of `GET /listings`, as described in server/swagger.yaml.
nonisolated struct ListingFeedDTO: Decodable {
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
    let items: [ListingDTO]
}

/// Raw JSON shape of one listing.
/// Property names must match the snake_case keys once converted to camelCase.
nonisolated struct ListingDTO: Decodable {
    let id: Int
    let categoryId: Int
    let title: String
    let description: String
    let price: Double
    let creationDate: Date
    let isUrgent: Bool
    let imagesUrl: ImagesDTO?

    nonisolated struct ImagesDTO: Decodable {
        let small: String?
        let thumb: String?
    }
}

nonisolated extension ListingDTO {
    /// Converts the raw API object into the clean domain model.
    func toDomain(baseURL: URL) -> Listing {
        Listing(
            id: id,
            categoryID: categoryId,
            title: title,
            description: description,
            price: price,
            creationDate: creationDate,
            isUrgent: isUrgent,
            images: ListingImages(
                small: Self.resolve(imagesUrl?.small, against: baseURL),
                thumb: Self.resolve(imagesUrl?.thumb, against: baseURL)
            )
        )
    }

    /// Turns a server-relative path ("/images/ad-small/x.jpg") into a full URL
    /// ("http://localhost:8080/images/ad-small/x.jpg").
    /// Returns nil when the path is missing or blank.
    static func resolve(_ path: String?, against baseURL: URL) -> URL? {
        guard let path, !path.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }
}
