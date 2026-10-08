# Native updates

The direct `WindowCleaner` target uses Sparkle 2.10 with the completed signed release artifacts. Update access is separated from GitHub release publishing: clients never receive signing keys or a shared publisher token.

This repository is already public. Anonymous release discovery and downloads are supported; an optional per-user read-only GitHub token can raise API limits. Existing repository visibility is unchanged.

Checks require a stable release containing uploaded `appcast.xml`, `release.json` and `WindowCleaner-<version>-universal.zip`. Drafts, prereleases, missing/unuploaded artifacts and invalid metadata are ignored. Downloads preserve the original signed feed and use a nonce-scoped loopback bridge. Archive fetching is lazy; checking does not download the archive. GitHub credentials are stripped on allowlisted artifact redirects, and foreign origins are rejected. Sparkle verifies archive signatures.

Automatic checking and automatic installation are separate persisted preferences. Automatic installation defaults off. Manual checks remain available. Installation requires an explicit restart confirmation, rechecks lifecycle safety after confirmation, and retains the downloaded installation callback when deferred; use Install Downloaded Update when ready. Active store operations, pending SwiftData edits and open native document/sheet work prevent restart.

The `WindowCleanerAppStore` target defines `APP_STORE` and uses an independent plist and original entitlements. It has no Sparkle product dependency, linked framework, updater UI or updater plist keys. This separate target prevents a compile flag from accidentally leaving the self-updater linked. Existing Store/payment capabilities and distribution identities are preserved; Store eligibility and notarization remain distribution checks.

## Verification

`Scripts/test-update-transport.sh` compiles a standalone fixture executable, without launching the app or opening its user data. It verifies stable/uploaded artifact metadata, malformed/foreign feeds, cache-free loopback feed bytes, no archive download during discovery, expired access and redirect credential removal.

`xcodebuild -project WindowCleaner.xcodeproj -scheme WindowCleanerUpdates -destination 'platform=macOS' -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test` runs the independent unhosted updater test target. It compiles the updater implementation directly, verifies preferences/credentials/deferral safety, and bypasses unrelated legacy template test fixtures.

`xcodebuild -project WindowCleaner.xcodeproj -scheme WindowCleanerAppStore -configuration Release -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build` verifies the updater-free Store variant. The updater CI additionally checks `otool` linkage, framework absence and Store plist keys.

Unsigned local builds establish compiler and linkage correctness; release signing/notarization and a live upgrade require completed signed artifacts through the separately documented release workflow. No test here publishes releases or installs/relaunches an existing application.
