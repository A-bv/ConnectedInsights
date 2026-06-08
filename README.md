# InstagramGraph

`InstagramGraph` is a small Swift package between your Apple app (iOS/macOS) and Meta's Instagram Graph API.

Give it a valid Meta token and ask for hashtag media or Instagram analytics. It resolves the connected Instagram account, handles the Graph API calls, and returns results your app can use directly.

The implementation stays outside your app for easier testing, reuse, and updates.

Note: the Meta token should be generated using the [facebook/facebook-ios-sdk](https://github.com/facebook/facebook-ios-sdk).

## Installation

Add the package with Swift Package Manager to your iOS or macOS app:

```text
https://github.com/A-bv/InstagramGraph
```

## Usage

Import the package:

```swift
import InstagramGraph
```

Resolve credentials from the token, then create the service:

```swift
let resolver = InstagramGraphAccountResolver()

resolver.resolveCredentials(facebookToken: metaToken) { result in
    switch result {
    case .success(let credentials):
        let graphService = InstagramGraphService(credentials: credentials)
    case .failure(let error):
        print(error)
    }
}
```

Search hashtag media:

```swift
graphService.searchHashtag(searchedHashtag: "travel") { result in
    switch result {
    case .success(let media):
        print(media)
    case .failure(let error):
        print(error)
    }
}
```

Load profile analytics:

```swift
graphService.loadProfileForAnalytics(mediaLimit: 12) { result in
    print(result)
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
