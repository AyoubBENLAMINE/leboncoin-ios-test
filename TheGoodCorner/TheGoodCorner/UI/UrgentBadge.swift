import SwiftUI

/// "Urgent" tag. Black on orange keeps a high contrast ratio in light and dark mode.
struct UrgentBadge: View {
    var body: some View {
        Label("Urgent", systemImage: "bolt.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.orange, in: Capsule())
    }
}
