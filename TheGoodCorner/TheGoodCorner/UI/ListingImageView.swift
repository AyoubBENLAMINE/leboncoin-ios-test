import SwiftUI

/// Remote listing image with explicit placeholders for the three "no picture" cases:
/// no URL from the API, image still loading, and image failed to load (e.g. 404).
/// Hidden from VoiceOver: the listing title already describes the content.
struct ListingImageView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ZStack {
                            background
                            ProgressView()
                        }
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private var background: some View {
        Color.secondary.opacity(0.15)
    }

    private var placeholder: some View {
        ZStack {
            background
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
