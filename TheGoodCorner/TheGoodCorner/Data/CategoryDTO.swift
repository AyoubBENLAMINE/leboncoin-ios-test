import Foundation

/// Raw JSON shape of one item of `GET /categories`.
nonisolated struct CategoryDTO: Decodable {
    let id: Int
    let name: String
}

nonisolated extension CategoryDTO {
    func toDomain() -> ListingCategory {
        ListingCategory(id: id, name: name)
    }
}
