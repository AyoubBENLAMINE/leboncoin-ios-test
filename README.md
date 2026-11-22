# TheGoodCorner – iOS technical test

SwiftUI app (iOS 16+) that displays leboncoin-style listings from the local API in `server/`.

The original exercise instructions are in the upstream repository: [leboncoin/iOS-Test-Recruitment](https://github.com/leboncoin/iOS-Test-Recruitment).
Assumptions, trade-offs and AI usage are described in [REFLECTION.md](REFLECTION.md).

## Run

1. Start the API (unchanged from the starter):
   ```bash
   cd server
   swift run
   ```
   The server listens on `http://localhost:8080`.
2. Open `TheGoodCorner/TheGoodCorner.xcodeproj` and run the `TheGoodCorner` scheme on an iPhone simulator.

To run on a physical device, set the `API_BASE_URL` environment variable in the scheme (Run › Arguments), e.g. `http://192.168.1.10:8080`.

## Test

Press ⌘U in Xcode. The tests do not need the server.

## Features

- Listing feed in API order (urgent first, then newest): image, urgent badge, title, category, price
- Category filter (toolbar menu)
- Detail screen with all the fields returned by the API
- Loading, error with retry, and empty states; pull to refresh
- Graceful handling of missing or broken images
- VoiceOver labels and Dynamic Type support

## Project structure

```
TheGoodCorner/TheGoodCorner/
├── Domain/      Listing, ListingCategory, ListingsRepository (protocol)
├── Data/        DTOs + JSON decoding, Endpoint, APIClient
├── Features/
│   ├── ListingList/    ListingListViewModel, ListingListView, ListingRow
│   └── ListingDetail/  ListingDetailView
├── UI/          Reusable views (image, urgent badge, state messages) and price formatting
└── TheGoodCornerApp.swift   Composition root and base URL configuration
```
