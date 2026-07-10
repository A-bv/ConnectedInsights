# ConnectedInsights

[![CI](https://github.com/A-bv/ConnectedInsights/actions/workflows/ci.yml/badge.svg)](https://github.com/A-bv/ConnectedInsights/actions/workflows/ci.yml)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Platforms](https://img.shields.io/badge/platform-iOS%2015%2B%20%7C%20macOS%2012%2B-blue)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen)
![Graph API](https://img.shields.io/badge/Meta%20Graph%20API-v23.0-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

**The implementation layer between Meta's Instagram Graph API and your app's data.** A small Swift package for Apple apps (iOS/macOS): hand it a valid Meta token and get typed hashtag media and Instagram profile analytics back — skipping the Graph API request-building, pagination fields, and JSON decoding in between.

- **Three calls, one entry point.** `searchHashtag(_:)`, `loadProfileForAnalytics(mediaLimit:)`, and `businessDiscovery(account:)` on a single `ConnectedInsightsGateway`.
- **Typed results.** `Profile`, `InstagramPost`, and insight metrics — no dictionaries, no manual `CodingKeys`.
- **Secure by default.** Credentials are stored in the Keychain (not synced, not backed up), or kept entirely in your own store if you prefer.
- **Diagnostic errors.** Meta HTTP failures and schema drift surface as a typed `InstagramGraphServiceError` that names the failing field.

> **ConnectedInsights does not perform Facebook Login.** Your app supplies the Meta token — obtain it with [Facebook Login for iOS](https://developers.facebook.com/docs/facebook-login/ios), or generate one manually for testing via [Live Meta Tests](#live-meta-tests).

## Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Returned types](#returned-types)
- [Error handling](#error-handling)
- [Credentials & security](#credentials--security)
- [Testing](#testing)
- [License](#license)

## Requirements
iOS 15 · macOS 12 · Swift 6 (Xcode 16+) · Targets **Meta Graph API v23.0**

The token must carry the `instagram_basic`, `instagram_manage_insights`, and `pages_show_list` permissions, and the account must be an Instagram Business or Creator account linked to a Facebook Page.

## Installation
Add the package in Xcode (*File ▸ Add Package Dependencies…*) or in your `Package.swift`:

```swift
.package(url: "https://github.com/A-bv/ConnectedInsights", from: "4.0.0")
```

Then add `"ConnectedInsights"` to your target's dependencies.

## Usage
Create one gateway, call `setup` once after the user authenticates, then check `accessState()` before each data call.

```swift
import ConnectedInsights

let gateway = ConnectedInsightsGateway()

// Call once after the user logs in with Facebook. Credentials are persisted,
// so you do not need to call setup again on the next launch.
try await gateway.setup(facebookToken: metaToken)

switch gateway.accessState() {
case .ready:
    let profile = try await gateway.loadProfileForAnalytics(mediaLimit: 12)
    let posts = try await gateway.searchHashtag(searchedHashtag: "travel")
    let competitor = try await gateway.businessDiscovery(account: "natgeo")

case .needsSetup(let error):
    // Setup is incomplete or credentials are missing; error explains why.
    print(error.localizedDescription)
}
```

`loadProfileForAnalytics(mediaLimit:)` caps how many recent media items are returned; pass `nil` (or use the no-argument `loadProfileForAnalytics()` overload) for all available media. `searchHashtag(_:)` takes a hashtag **without** the `#` prefix and returns the most recent matching public posts.

`businessDiscovery(account:)` returns another public account's `Profile` and recent media (e.g. to compare against a competitor). The handle is accepted with or without a leading `@`; it's validated before use, so a malformed handle throws `InstagramGraphServiceError.invalidAccountUsername` rather than hitting the network. Note Meta's constraint: the queried account must be a Business/Creator account, and **your** connected account must be a **Business** account — `business_discovery` is unavailable to Creator accounts.

Call `reset()` to clear stored credentials and force a fresh `setup`.

## Returned types
All models are `public`, `Decodable`, and `Hashable`. Optional fields reflect that Meta may omit them depending on the account and requested permissions.

| Type | Key fields |
| --- | --- |
| `Profile` | `username`, `name`, `biography`, `followersCount`, `followsCount`, `mediaCount`, `profilePictureUrl`, `website`, `insights: ProfileInsights?`, `media: Media?` |
| `InstagramPost` | `mediaType`, `caption`, `timestamp`, `mediaUrl`, `likeCount`, `commentsCount`, `isCommentEnabled`, `username`, `insights: PostInsights?` |
| `InstagramMediaType` | `.image` · `.video` · `.carouselAlbum` · `.unknown(String)` — the `.unknown` case keeps decoding forward-compatible when Meta adds a new media type |
| `Media` / `ProfileInsights` / `PostInsights` | `data: [...]` wrappers around posts and `InsightMetric` values |
| `InsightMetric` | `name`, `period`, `values: [InsightValue]` (each `InsightValue` has `value` and `endTime`) |

`loadProfileForAnalytics` returns a `Profile` whose `media.data` holds the recent `InstagramPost`s; `searchHashtag` returns `[InstagramPost]` directly.

## Error handling
`setup` and both data calls are `async throws`. Failures surface as a typed `InstagramGraphServiceError`, so you can branch on the cause instead of parsing strings:

```swift
do {
    let profile = try await gateway.loadProfileForAnalytics()
} catch let error as InstagramGraphServiceError {
    switch error {
    case .graphHTTPError(let statusCode, let body):
        // Non-2xx from Meta (e.g. an expired token). Access tokens are redacted from `body`.
        print("Graph error \(statusCode): \(body)")
    case .decodingFailed(let type, let body):
        // Meta changed the response schema; `body` names the failing coding path.
        print("Could not decode \(type): \(body)")
    case .instagramAccountNotFound:
        print("No Instagram Business/Creator account is linked to a Facebook Page for this token.")
    case .invalidAccountUsername(let handle):
        // A malformed handle passed to businessDiscovery(account:); rejected before any request.
        print("Not a valid Instagram username: \(handle)")
    case .networkError, .emptyResponse, .invalidURL, .missingCredentials:
        print(error.localizedDescription)
    }
}
```

## Credentials & security
`setup(facebookToken:)` stores the Meta token and the resolved Instagram business-account id in the **Keychain** — accessible only after first unlock, and never synced to iCloud or included in device backups (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`). They survive app restarts, so `setup` only needs to run once after login.

- **Migration.** Credentials persisted in `UserDefaults` by versions ≤ 3.0.2 are moved into the Keychain automatically on first use. The plaintext copy is removed only after the Keychain write is confirmed by read-back, so a failed write never destroys the credential — migration retries on the next launch.
- **Bring your own store.** To keep the token entirely in your own storage, inject an `InstagramGraphAccessTokenProviding` via `ConnectedInsightsGateway(tokenProvider:)`; the package then never persists the token itself.
- **Logging.** Requests are logged via `OSLog` with `access_token` values redacted.
- **macOS note.** Keychain access requires the app to be signed with the appropriate data-protection / Keychain Sharing entitlement. Validate credential persistence in a signed build before shipping.

## Testing
Unit tests run offline against an in-memory Keychain fake and a stubbed URL session:

```sh
swift test
```

### Live Meta tests
Exercise the real Graph API. Requires a valid token from the [Meta Graph API Explorer](https://developers.facebook.com/tools/explorer/):

```sh
META_GRAPH_TOKEN="..." swift test --filter MetaLiveTests
# Target a specific hashtag (default: travel):
META_GRAPH_TOKEN="..." META_TEST_HASHTAG="cars" swift test --filter MetaLiveTests
# Target a business_discovery account (default: natgeo):
META_GRAPH_TOKEN="..." META_TEST_DISCOVERY_ACCOUNT="nike" swift test --filter MetaLiveTests
```

Meta limits hashtag search to 30 unique hashtags per 7 days. **Do not commit tokens or account secrets.**

### Live Keychain tests
Verify credential storage against the real system Keychain (gated separately because Keychain access can be unavailable in headless CI):

```sh
RUN_KEYCHAIN_LIVE=1 swift test --filter KeychainStoreLiveTests
```

## License
Released under the [MIT License](LICENSE).
