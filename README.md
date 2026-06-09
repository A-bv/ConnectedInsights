# InstagramGraph

A small Swift package that simplifies communication between your Apple app (iOS/macOS) and Meta's Instagram Graph API.

It takes a valid Meta token as input and outputs hashtag media or Instagram analytics, skipping the Graph API implementation work in between.

The implementation stays outside your app for easier testing, reuse, and updates.

Note: get the Meta token in your app with [Facebook Login for iOS](https://developers.facebook.com/docs/facebook-login/ios), or generate one manually with [Live Meta Tests](#live-meta-tests).

## Installation

Add the package with Swift Package Manager to your iOS or macOS app:

```text
https://github.com/A-bv/InstagramGraph
```

## Usage

```swift
import InstagramGraph

let resolver = InstagramGraphAccountResolver()

resolver.resolveCredentials(facebookToken: metaToken) { result in
    switch result {
    case .success(let credentials):
        let graphService = InstagramGraphService(credentials: credentials)

        graphService.searchHashtag(searchedHashtag: "travel") { result in
            print(result)
        }

        graphService.loadProfileForAnalytics(mediaLimit: 12) { result in
            print(result)
        }

    case .failure(let error):
        print(error)
    }
}
```

`mediaLimit` is optional. Use it when the app wants to cap analytics media.

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

Or, if you want to test a specific hashtag:

```sh
META_GRAPH_TOKEN="..." META_TEST_HASHTAG="cars" swift test --filter MetaLiveTests
```

Default hashtag: `travel`. Meta limits hashtag search to 30 unique hashtags per 7 days.

Do not commit tokens or account secrets.
