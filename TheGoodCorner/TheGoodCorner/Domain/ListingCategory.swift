import Foundation

/// A listing category (e.g. "Véhicule", "Mode").
nonisolated struct ListingCategory: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
}
