import Foundation

nonisolated extension JSONDecoder {
    /// Decoder configured for the TheGoodCorner API:
    /// - snake_case keys ("category_id") map to camelCase properties ("categoryId")
    /// - dates are ISO 8601 ("2019-11-06T11:22:35Z")
    static func makeAPIDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
