# InstagramGraph

`InstagramGraph` is a Swift package for iOS apps that call Meta's Instagram Graph API.

It keeps Graph API details out of the app layer: endpoint construction, credential validation, network calls, and response decoding live in one package instead of being spread through SwiftUI or UIKit code.

## What It Covers

- Hashtag search and top media results.
- Instagram Business / Creator profile data for analytics.
- Typed Swift models for Graph API responses.
- Unit and live tests to detect Meta API changes.

## Caller Inputs

The app decides the product behavior. The package provides the API plumbing.

- `apiGraphVersion`: choose the Meta Graph API version to use. If omitted, the package uses its production default.
- `facebookToken`: pass a valid Meta access token from your app/session.
- `instagramBusinessAccountId`: pass the Instagram Business / Creator account id.
- `mediaLimit`: optional. Use it when the app wants to cap profile media fetched for analytics. Leave it empty to let Meta return its default page.

## Installation

Add the package with Swift Package Manager:

```text
https://github.com/A-bv/InstagramGraph
```

Import it:

```swift
import InstagramGraph
```

## Usage

Create the service:

```swift
let graphService = InstagramGraphService()
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

Load profile analytics with Meta's default media page size:

```swift
graphService.loadProfileForAnalytics { result in
    print(result)
}
```

Load profile analytics with an app-defined media limit:

```swift
graphService.loadProfileForAnalytics(mediaLimit: 12) { result in
    print(result)
}
```

If a profile has fewer than `mediaLimit` media items, Meta returns only the available items. If it has more, Meta returns up to the requested limit.

## Tests

Run local unit tests:

```sh
swift test
```

Run live tests against Meta:

```sh
META_GRAPH_TOKEN="..." \
META_PAGE_ID="..." \
META_IG_BUSINESS_ID="..." \
META_TEST_HASHTAG="travel" \
swift test --filter MetaLiveTests
```

Live tests are skipped when required variables are missing.

## Getting A Meta Token

Use Meta Graph API Explorer:

[https://developers.facebook.com/tools/explorer/](https://developers.facebook.com/tools/explorer/)

In the Explorer:

1. Select your Meta app.
2. Select a user token with access to the Facebook Page connected to the Instagram Business / Creator account.
3. Add the permissions needed by your flow, for example `instagram_basic`, `pages_show_list`, and the page/business permissions required by your setup.
4. Click **Generate Access Token**.
5. Copy the token into `META_GRAPH_TOKEN`.

Do not commit tokens or account secrets.

## Live Test Inputs

- `META_GRAPH_TOKEN`: access token copied from Meta Graph API Explorer.
- `META_PAGE_ID`: Facebook Page id. The `/me/accounts` live test can help confirm it.
- `META_IG_BUSINESS_ID`: Instagram Business / Creator account id connected to the page.
- `META_TEST_HASHTAG`: hashtag used by the live hashtag search test.
- `META_GRAPH_VERSION`: optional Meta Graph API version override.
- `META_MEDIA_LIMIT`: optional profile media limit for the analytics live test.
