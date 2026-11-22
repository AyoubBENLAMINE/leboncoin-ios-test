import SwiftUI

/// Feed screen: loading, error, empty and content states, category filter, navigation to detail.
struct ListingListView: View {
    @StateObject private var viewModel: ListingListViewModel

    init(viewModel: @autoclosure @escaping () -> ListingListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Annonces")
                .toolbar { categoryFilter }
                .navigationDestination(for: Listing.self) { listing in
                    ListingDetailView(listing: listing,
                                      categoryName: viewModel.categoryName(for: listing))
                }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Chargement des annonces…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            StateMessageView(systemImage: "wifi.exclamationmark",
                             title: "Impossible de charger les annonces",
                             message: "Vérifiez votre connexion puis réessayez.",
                             actionTitle: "Réessayer") {
                Task { await viewModel.load() }
            }
        case .loaded:
            if viewModel.visibleListings.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var list: some View {
        List(viewModel.visibleListings) { listing in
            NavigationLink(value: listing) {
                ListingRow(listing: listing, categoryName: viewModel.categoryName(for: listing))
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var emptyState: some View {
        if let categoryName = viewModel.selectedCategoryName {
            StateMessageView(systemImage: "tray",
                             title: "Aucune annonce",
                             message: "Aucune annonce dans la catégorie « \(categoryName) ».",
                             actionTitle: "Voir toutes les annonces") {
                viewModel.selectedCategoryID = nil
            }
        } else {
            StateMessageView(systemImage: "tray",
                             title: "Aucune annonce",
                             message: "Il n'y a aucune annonce pour le moment.",
                             actionTitle: "Actualiser") {
                Task { await viewModel.load() }
            }
        }
    }

    @ToolbarContentBuilder
    private var categoryFilter: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Picker("Catégorie", selection: $viewModel.selectedCategoryID) {
                    Text("Toutes les catégories").tag(ListingCategory.ID?.none)
                    ForEach(viewModel.categories) { category in
                        Text(category.name).tag(ListingCategory.ID?.some(category.id))
                    }
                }
            } label: {
                Image(systemName: viewModel.selectedCategoryID == nil
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
            }
            .accessibilityLabel("Filtrer par catégorie")
            .accessibilityValue(viewModel.selectedCategoryName ?? "Toutes les catégories")
            .disabled(viewModel.state != .loaded)
        }
    }
}
