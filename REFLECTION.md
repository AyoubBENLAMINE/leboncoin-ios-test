# Reflection

## Scope

All core requirements are implemented: listing feed with image, category, title, price and urgent badge, API order preserved, category filter, detail screen, loading / error (with retry) / empty states, accessibility basics, and 9 deterministic unit tests.

No bonus option was implemented. I preferred a solid, tested core over extra scope.

## Assumptions and ambiguities

| Topic | What I found | What I did |
|---|---|---|
| Category filter | `GET /listings` has no category parameter. | Filtering is done in the app on the full feed. Without `page`/`limit`, the API returns all 300 listings in one call. |
| Pagination vs filter | Filtering only the pages already loaded would show wrong (incomplete) results. | No pagination: the full feed is loaded once, then filtered locally. |
| Display order | The API already sorts (urgent first, then newest). | The app never re-sorts. Filtering preserves the order (covered by a test). |
| Missing images | Three cases: `images_url: null`, `small`/`thumb` set to `null`, and 5 listings pointing to `poisoned-image.jpg`, which returns 404. | Blank or missing paths become `nil` (tested). The UI shows a neutral placeholder for "no URL" and "load failed", and a spinner while loading. `small` is used in the list and `thumb` in the detail, each falling back to the other. |
| Currency | The API sends a number with no currency. | Euros are assumed. The format follows the device locale: "10 €" in French, "€10" on an English simulator. |
| Dates | All listings date from 2019. | The detail screen shows an absolute date and time, not a relative "7 years ago". |
| `siret` | Present in the seed data (22 professional sellers) but not exposed by the API DTO. | Not displayed: the app can only show what the API returns. |
| Unknown category id | Possible in theory. | The row hides the category, and the detail shows "Catégorie inconnue". No crash (tested). |
| Categories request fails | The screen needs both requests. | The whole screen shows the error state with retry. This is simpler; a degraded mode (listings without the filter) would be a possible next step. |
| Language | The prompt does not specify one. | UI strings are in French (leboncoin audience) and hardcoded. A String Catalog would be the next step for localization. |
| Device | The starter enables iPhone and iPad. | Designed and checked for iPhone in the Simulator (the reference runtime). iPad works but is not specifically adapted. |
| Physical device | `localhost` only works in the Simulator. | The base URL can be overridden with the `API_BASE_URL` environment variable in the scheme. |

## Architecture

```
SwiftUI views ──▶ ListingListViewModel (@MainActor, ObservableObject)
                        │ depends on
                        ▼
                ListingsRepository (protocol)
                        ▲ implemented by
                    APIClient ──▶ HTTPClient (protocol) ──▶ URLSession
                        │
                    DTOs (Decodable) ──toDomain()──▶ Listing / ListingCategory
```

- **MVVM with a repository protocol.** The view model only knows `ListingsRepository`, so its logic is tested with an in-memory fake. `APIClient` only knows `HTTPClient`, so HTTP behaviour (status codes, malformed JSON) is tested with a stub, without a server.
- **DTO vs domain models.** DTOs mirror the JSON (snake_case, server-relative image paths, nullable objects). `toDomain()` turns them into clean models (absolute `URL?`, one shape for "no image"). Views never see API quirks.
- **Typed errors.** Transport, HTTP status and decoding errors are mapped to a small `APIError` enum. A cancelled request is not treated as an error.
- **`ObservableObject`, not `@Observable`.** `@Observable` requires iOS 17, and the deployment target is iOS 16.
- **Concurrency.** The starter sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Data types (DTOs, domain models, `APIClient`) are marked `nonisolated` so decoding and networking are not tied to the main actor. The view model stays on the main actor. Listings and categories are fetched in parallel with `async let`.
- **No external dependencies**, no storyboards. `server/` is untouched.

## Tests

9 unit tests, deterministic, no server required:

- `ListingDecodingTests`: full field mapping (snake_case, ISO 8601 date, absolute image URLs); the three "missing image" shapes; categories.
- `APIClientTests`: request building (blank query dropped, accents and `+` escaped); HTTP 500 mapped to `APIError.httpStatus`; malformed JSON mapped to `APIError.decoding`.
- `ListingListViewModelTests`: API order preserved with category names (and an unknown category); category filter without re-ordering; error state recovered by retry.

The Xcode template tests were removed. The UI test template target is skipped and unit tests run serially in the shared scheme: the template UI tests add no value and were exhausting the simulator resources on the machine I used.

## Accessibility

- Each row is a single VoiceOver element ("Urgent, title, category, price"); images are decorative and hidden from VoiceOver.
- Dynamic Type: system text styles everywhere, the thumbnail size scales with `@ScaledMetric`, and rows switch to a vertical layout at accessibility sizes.
- The filter button has a label ("Filtrer par catégorie") and a value (the selected category).
- The "Description" title is marked as a header.
- The urgent badge uses black text on orange for contrast.

## Known limitations and next steps

- Images use `AsyncImage` with the default `URLCache`. A small image loader with an in-memory cache would avoid reloading thumbnails when scrolling back.
- A failed pull-to-refresh keeps the current content but shows no message; a non-blocking banner would be better.
- No UI or snapshot tests.
- Remaining Xcode warnings are not from the app code: Xcode's "Update to recommended settings" (left unapplied to keep the starter project settings unchanged) and XCTest linking warnings caused by Xcode 27 with an iOS 16 deployment target.

## AI usage

**Tool:** Claude (Anthropic), used as a pair programmer throughout the exercise: reading the starter and the API to list ambiguities, proposing the architecture and the commit plan, drafting code and tests step by step, and guiding Git. I ran every step, built and tested it in the simulator, reviewed the diffs and committed incrementally.

**AI suggestions that I rejected, corrected or rewrote:**

1. **Endpoint URL building did not compile.** The first version read and wrote `components?.percentEncodedQuery` in the same statement. The compiler reported an overlapping access (Swift exclusivity rule). I rewrote it by unwrapping `URLComponents` once with `guard`, then reading and writing in two statements.
2. **Concurrency isolation.** The first DTOs and models did not account for the project's MainActor default isolation, which produced warnings as soon as they were used from the tests. I marked the data types `nonisolated`.
3. **Test configuration that did not persist.** Excluding UI tests and disabling parallel testing through Xcode's test plan editor was not saved in the shared scheme, even though my commit message said so. I caught it by re-reading the committed XML and fixed the scheme directly (commit "fix: actually skip UI tests…").
4. **Commit hygiene.** A suggested `git add` mixed in test files that Xcode had already staged, including its automatic file header with the macOS account name of the machine I was using. I undid that local commit with `git reset`, removed the headers and recommitted cleanly. I also reverted unrelated `project.pbxproj` changes that Xcode made through its bridging-header prompt.

**Decisions I owned:**

- Validating the layered MVVM + repository architecture and the step-by-step commit plan before writing code.
- Scope: core requirements only, no bonus, within the time I gave myself.
- Keeping leboncoin's project settings and `server/` untouched, and keeping only intentional changes in the history.
- Checking every step myself in the simulator, including the error and retry flow with the server stopped.
