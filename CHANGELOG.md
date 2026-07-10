# Changelog

All notable changes to this project are documented here. This project adheres to
[Semantic Versioning](https://semver.org).

## [4.1.0] - 2026-07-10

### Added
- `ConnectedInsightsGateway.businessDiscovery(account:)` — fetches another public account's
  `Profile` and recent media via Meta's `business_discovery` field (e.g. for competitor analysis).
  The handle is accepted with or without a leading `@` and is strictly validated before use, so a
  malformed handle throws `InstagramGraphServiceError.invalidAccountUsername` without a network
  round-trip. The queried account must be a Business/Creator account, and the caller's own account
  must be a Business account (a Meta constraint on `business_discovery`).
- `InstagramGraphServiceError.invalidAccountUsername(_:)` for handles that are empty, too long, or
  contain characters outside the permitted set. **Note:** consumers that switch exhaustively over
  `InstagramGraphServiceError` will need to handle the new case.

## [4.0.0] - 2026-07-10

### Changed
- **Renamed the package and module from `InstagramGraph` to `ConnectedInsights`.** "Instagram" is a
  Meta trademark; the library now uses it only descriptively (it is a client *for* the Instagram
  Graph API) rather than as the product name. **Breaking:** update your dependency URL to
  `.../ConnectedInsights` and change `import InstagramGraph` to `import ConnectedInsights`. The
  public API (types, methods, `InstagramGraphServiceError`) is otherwise unchanged; GitHub redirects
  the old repository URL so existing Swift Package Manager references keep resolving.
- **Adopted the Swift 6 language mode** (`swift-tools-version: 6.0`, `swiftLanguageModes: [.v6]`).
  Builds clean under complete strict concurrency. Deployment targets are unchanged (iOS 15 / macOS
  12); consuming the package now requires the Swift 6 compiler (Xcode 16+).
- The public response models (`Profile`, `InstagramPost`, `InstagramMediaType`, and the insight
  types) and internal configuration/value types now conform to `Sendable`, so results cross the
  `@MainActor` gateway's isolation boundary cleanly under strict concurrency.

## [3.1.0] - 2026-06-29

### Security
- Credentials (the Meta token and resolved Instagram business-account id) are now stored in the
  **Keychain** instead of `UserDefaults`, using `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
  so they are not synced to iCloud or included in device backups.
- Credentials persisted in `UserDefaults` by versions ≤ 3.0.2 are migrated into the Keychain
  automatically on first use. The plaintext copy is removed only after the Keychain write is
  confirmed by read-back, so a failed write never destroys the credential — migration is retried
  on the next launch.
- User-supplied values (hashtag search terms) are strictly percent-encoded when building Graph
  API URLs, closing a query-injection vector where characters such as `&`, `=`, and `+` could
  break out of the `q` parameter.

### Changed
- Graph API URLs are now assembled with `URLComponents` for consistent, correct encoding.
- Decoding failures now surface the failing coding path / type (not just a body preview), making
  Graph API schema changes easier to diagnose.

### Notes
- **macOS integrators:** Keychain access requires the app to be signed with the appropriate
  data-protection / Keychain Sharing entitlement. Validate credential persistence in a signed
  build before shipping.

## [3.0.2]
- Previous releases. See git history.
