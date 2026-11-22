import Foundation

/// Raw JSON shape of one item of `GET /categories`.
struct CategoryDTO: Decodable {
    let id: Int
    let name: String
}

extension CategoryDTO {
    func toDomain() -> ListingCategory {
        ListingCategory(id: id, name: name)
    }
}
