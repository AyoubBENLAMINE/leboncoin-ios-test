import Foundation

nonisolated enum PriceFormatter {
    /// Formats a listing price, e.g. "140 €" or "765 000 €" in French.
    /// The API sends no currency: euros are assumed (documented in REFLECTION.md).
    static func string(from price: Double, locale: Locale = .current) -> String {
        price.formatted(.currency(code: "EUR")
            .locale(locale)
            .precision(.fractionLength(0...2)))
    }
}
