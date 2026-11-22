import Foundation
import SwiftUI

/// Detail screen: every field returned by the API, in a readable, scrollable layout.
struct ListingDetailView: View {
    let listing: Listing
    let categoryName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Color.secondary.opacity(0.1)
                    .aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay {
                        ListingImageView(url: listing.images.thumb ?? listing.images.small)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    if listing.isUrgent {
                        UrgentBadge()
                    }
                    Text(listing.title)
                        .font(.title2.weight(.bold))
                    Text(PriceFormatter.string(from: listing.price))
                        .font(.title3.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label(categoryName ?? "Catégorie inconnue", systemImage: "tag")
                    Label("Publiée le \(listing.creationDate.formatted(date: .long, time: .shortened))",
                          systemImage: "calendar")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text("Description")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(listing.description.isEmpty ? "Aucune description." : listing.description)
                    .font(.body)
                    .textSelection(.enabled)

                Text(verbatim: "Réf. \(listing.id)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
