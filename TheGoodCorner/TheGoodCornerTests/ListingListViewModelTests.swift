import XCTest
@testable import TheGoodCorner

/// In-memory repository: lets each test decide what the "API" returns.
private final class FakeListingsRepository: ListingsRepository, @unchecked Sendable {
    var listingsResult: Result<[Listing], Error>
    var categoriesResult: Result<[ListingCategory], Error>

    init(listings: Result<[Listing], Error>,
         categories: Result<[ListingCategory], Error> = .success([])) {
        self.listingsResult = listings
        self.categoriesResult = categories
    }

    func fetchListings(query: String?) async throws -> [Listing] { try listingsResult.get() }
    func fetchCategories() async throws -> [ListingCategory] { try categoriesResult.get() }
}

private func makeListing(id: Int, categoryID: Int, isUrgent: Bool = false) -> Listing {
    Listing(id: id, categoryID: categoryID, title: "Listing \(id)", description: "",
            price: 10, creationDate: Date(timeIntervalSince1970: 0),
            isUrgent: isUrgent, images: .none)
}

@MainActor
final class ListingListViewModelTests: XCTestCase {

    // API order: urgent #3 first, then #1, then #2. The view model must not re-sort.
    private let apiOrder = [
        makeListing(id: 3, categoryID: 1, isUrgent: true),
        makeListing(id: 1, categoryID: 2),
        makeListing(id: 2, categoryID: 1)
    ]

    func test_load_success_exposesListingsInAPIOrderWithCategoryNames() async {
        let viewModel = ListingListViewModel(repository: FakeListingsRepository(
            listings: .success(apiOrder),
            categories: .success([ListingCategory(id: 1, name: "Véhicule")])
        ))

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.visibleListings.map(\.id), [3, 1, 2])
        XCTAssertEqual(viewModel.categoryName(for: apiOrder[0]), "Véhicule")
        XCTAssertNil(viewModel.categoryName(for: apiOrder[1]), "unknown category id must not crash")
    }

    func test_selectingCategory_filtersWithoutReordering() async {
        let viewModel = ListingListViewModel(repository: FakeListingsRepository(listings: .success(apiOrder)))
        await viewModel.loadIfNeeded()

        viewModel.selectedCategoryID = 1
        XCTAssertEqual(viewModel.visibleListings.map(\.id), [3, 2])

        viewModel.selectedCategoryID = nil
        XCTAssertEqual(viewModel.visibleListings.map(\.id), [3, 1, 2])
    }

    func test_loadFailure_isRecoverableByRetrying() async {
        let repository = FakeListingsRepository(listings: .failure(APIError.transport))
        let viewModel = ListingListViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .failed)

        repository.listingsResult = .success([makeListing(id: 1, categoryID: 1)])
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.visibleListings.map(\.id), [1])
    }
}
