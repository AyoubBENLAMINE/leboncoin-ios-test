import XCTest
@testable import TheGoodCorner

final class ListingDecodingTests: XCTestCase {

    private let baseURL = URL(string: "http://localhost:8080")!
    private let decoder = JSONDecoder.makeAPIDecoder()

    // 1. Happy path: every field lands in the right place.
    func test_decodeFeed_mapsAllFieldsToDomain() throws {
        let json = """
        {
          "total": 300, "page": 1, "limit": 1, "has_more": true,
          "items": [{
            "id": 1461267313,
            "category_id": 4,
            "title": "Statue homme noir assis",
            "description": "Magnifique statuette.",
            "price": 140,
            "creation_date": "2019-11-05T15:56:59Z",
            "is_urgent": true,
            "images_url": {
              "small": "/images/ad-small/abc.jpg",
              "thumb": "/images/ad-thumb/abc.jpg"
            }
          }]
        }
        """

        let feed = try decoder.decode(ListingFeedDTO.self, from: Data(json.utf8))
        let listing = try XCTUnwrap(feed.items.first).toDomain(baseURL: baseURL)

        XCTAssertEqual(feed.total, 300)
        XCTAssertTrue(feed.hasMore)
        XCTAssertEqual(listing.id, 1461267313)
        XCTAssertEqual(listing.categoryID, 4)
        XCTAssertEqual(listing.title, "Statue homme noir assis")
        XCTAssertEqual(listing.price, 140)
        XCTAssertTrue(listing.isUrgent)
        XCTAssertEqual(listing.creationDate, Date(timeIntervalSince1970: 1_572_969_419))
        XCTAssertEqual(listing.images.small?.absoluteString,
                       "http://localhost:8080/images/ad-small/abc.jpg")
        XCTAssertEqual(listing.images.thumb?.absoluteString,
                       "http://localhost:8080/images/ad-thumb/abc.jpg")
    }

    // 2. The API may omit images in three different ways; all must become nil.
    func test_decodeListing_withMissingImages_producesNilURLs() throws {
        let json = """
        [
          { "id": 1, "category_id": 1, "title": "A", "description": "",
            "price": 1, "creation_date": "2019-11-05T15:56:59Z", "is_urgent": false,
            "images_url": null },
          { "id": 2, "category_id": 1, "title": "B", "description": "",
            "price": 1, "creation_date": "2019-11-05T15:56:59Z", "is_urgent": false,
            "images_url": { "small": null, "thumb": null } },
          { "id": 3, "category_id": 1, "title": "C", "description": "",
            "price": 1, "creation_date": "2019-11-05T15:56:59Z", "is_urgent": false,
            "images_url": { "small": "", "thumb": "  " } }
        ]
        """

        let listings = try decoder.decode([ListingDTO].self, from: Data(json.utf8))
            .map { $0.toDomain(baseURL: baseURL) }

        XCTAssertEqual(listings.count, 3)
        for listing in listings {
            XCTAssertNil(listing.images.small, "listing \(listing.id) should have no small image")
            XCTAssertNil(listing.images.thumb, "listing \(listing.id) should have no thumb image")
        }
    }

    // 3. Categories decode and map to the domain type.
    func test_decodeCategories_mapsToDomain() throws {
        let json = """
        [{ "id": 1, "name": "Véhicule" }, { "id": 7, "name": "Livres/CD/DVD" }]
        """

        let categories = try decoder.decode([CategoryDTO].self, from: Data(json.utf8))
            .map { $0.toDomain() }

        XCTAssertEqual(categories, [
            ListingCategory(id: 1, name: "Véhicule"),
            ListingCategory(id: 7, name: "Livres/CD/DVD")
        ])
    }
}
