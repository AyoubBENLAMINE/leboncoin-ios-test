import SwiftUI

/// One listing in the feed: image, urgent badge, title, category and price.
struct ListingRow: View {
    let listing: Listing
    let categoryName: String?

    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 88
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility text sizes, stack vertically so the title keeps enough width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))

        layout {
            ListingImageView(url: listing.images.small ?? listing.images.thumb)
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                if listing.isUrgent {
                    UrgentBadge()
                }
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(3)
                if let categoryName {
                    Text(categoryName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(PriceFormatter.string(from: listing.price))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
        // VoiceOver reads the row as one element: "Urgent, title, category, price".
        .accessibilityElement(children: .combine)
    }
}
