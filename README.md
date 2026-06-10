# InstagramGraph

A small Swift package that simplifies communication between your Apple app (iOS/macOS) and Meta's Instagram Graph API.

It takes a valid Meta token as input and outputs hashtag media or Instagram profile analytics, skipping the Graph API implementation work in between.

Note: get the Meta token in your app with [Facebook Login for iOS](https://developers.facebook.com/docs/facebook-login/ios), or generate one manually with [Live Meta Tests](#live-meta-tests).

## Installation

Add the package with Swift Package Manager:

```text
https://github.com/A-bv/InstagramGraph
```

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

`mediaLimit` is optional. Omit it to load all available media.

## Getting Started

```sh
open Package.swift
```

## Live Meta Tests

Requires a valid token from [Meta Graph API Explorer](https://developers.facebook.com/tools/explorer/).

```sh
cd /path/to/InstagramGraph
META_GRAPH_TOKEN="..." swift test --filter MetaLiveTests
```

Or, to test a specific hashtag:

```sh
META_GRAPH_TOKEN="..." META_TEST_HASHTAG="cars" swift test --filter MetaLiveTests
```

Default hashtag: `travel`. Meta limits hashtag search to 30 unique hashtags per 7 days.

Do not commit tokens or account secrets.
