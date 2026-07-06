# InstagramGraph

Instagram analytics and hashtag search for Apple apps. A small Swift package that talks to Meta's Instagram Graph API for you: give it a valid Meta token and it returns hashtag media and Instagram profile analytics, skipping the Graph API implementation work in between.

![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)
![iOS 15+ | macOS 12+](https://img.shields.io/badge/platform-iOS%2015%2B%20%7C%20macOS%2012%2B-007AFF?logo=apple&logoColor=white)
![SPM](https://img.shields.io/badge/SPM-compatible-success)
![Meta Graph API v23.0](https://img.shields.io/badge/Meta%20Graph%20API-v23.0-0866FF?logo=meta&logoColor=white)

InstagramGraph does not perform Facebook Login. Your app must provide a valid Meta token: get it with [Facebook Login for iOS](https://developers.facebook.com/docs/facebook-login/ios), or generate one manually with [Live Meta Tests](#live-meta-tests).

## Install

Swift Package Manager. In Xcode, **File ▸ Add Package Dependencies…** and paste the URL:

```
https://github.com/A-bv/InstagramGraph
```

or declare it in `Package.swift`:

```swift
.package(url: "https://github.com/A-bv/InstagramGraph", from: "3.1.0")
```

> Targets **Meta Graph API v23.0**.

## Usage

```swift
import InstagramGraph

let gateway = ConnectedInsightsGateway()

// Call once after the user logs in with Facebook
try await gateway.setup(facebookToken: metaToken)
```

Then check the gateway state before making calls:

```swift
switch gateway.accessState() {
case .ready:
    let profile = try await gateway.loadProfileForAnalytics(mediaLimit: 12)
    let posts = try await gateway.searchHashtag(searchedHashtag: "travel")
case .needsSetup(let error):
    print(error.localizedDescription)
}
```

`mediaLimit` is optional. Use it to cap the number of recent media items returned for analytics.

The token must carry the `instagram_basic`, `instagram_manage_insights`, and `pages_show_list` permissions.

Setup and API calls are `async throws`; Meta HTTP errors and decoding errors are surfaced (as `InstagramGraphServiceError`) to help debug API changes.

## Credentials & security

`setup(facebookToken:)` stores the Meta token and resolved Instagram business-account id in the **Keychain** (accessible after first unlock, not synced or backed up); they survive app restarts, so you only call `setup` once after login. Credentials persisted by versions ≤ 3.0.2 in `UserDefaults` are migrated into the Keychain automatically. Call `reset()` to clear them. If you'd rather keep the token entirely in your own store, inject an `InstagramGraphAccessTokenProviding` via `ConnectedInsightsGateway(tokenProvider:)` and it won't be persisted by the package.

## Live Meta Tests

Requires a valid token from [Meta Graph API Explorer](https://developers.facebook.com/tools/explorer/).

```sh
META_GRAPH_TOKEN="..." swift test --filter MetaLiveTests
```

Or, to test a specific hashtag:

```sh
META_GRAPH_TOKEN="..." META_TEST_HASHTAG="cars" swift test --filter MetaLiveTests
```

Default hashtag: `travel`. Meta limits hashtag search to 30 unique hashtags per 7 days. Do not commit tokens or account secrets.

### Live Keychain Tests

Verifies credential storage against the real system Keychain (the unit tests use an in-memory fake). Gated separately because Keychain access can be unavailable in headless CI:

```sh
RUN_KEYCHAIN_LIVE=1 swift test --filter KeychainStoreLiveTests
```
