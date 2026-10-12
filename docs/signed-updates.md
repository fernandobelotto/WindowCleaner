# Signed direct macOS updates

The **Prepare signed update** workflow only runs on this repository's current main commit in the main-only `release` environment. Enter a stable semantic version; the workflow run number owns the monotonically increasing update build. Publication defaults off. Review the prepared artifact before dispatching with publish enabled.

Universal arm64/Intel application bytes are built from the exact commit with the selected release version/build, signed inside-out using Developer ID, notarized, stapled, verified by Gatekeeper and zipped. The final ZIP is signed with the app's unique Sparkle key and verified against SUPublicEDKey. ZIP and checksums upload into a draft, appcast is generated using the immutable archive asset ID, and release.json is uploaded last. Every uploaded artifact is downloaded and byte-compared before the release leaves draft status. Versions/builds cannot regress and published releases are never overwritten. A failed draft leaves the previous stable update usable.

Hosted signing and notarization credentials and SPARKLE_PRIVATE_KEY are configured in the repository's main-only release environment, with only the public updater key in the direct Info.plist. Store targets use separate Info files and do not receive self-update metadata. Existing bundle identities and entitlements are preserved. WindowCleaner remains public; update access is anonymous.

No workflow or release is triggered by implementation. A live two-version upgrade rehearsal, Apple notarization, and privileged-helper installation (where applicable) require an approved release run. Input version is release-owned and stamped into the prepared artifact; it does not silently edit the source project version.

The workflow creates a new GitHub draft release and version tag from the exact approved main commit. It rejects a tag or release that already exists, signs the final stapled bytes and publishes only after the complete marker and all assets verify. Vendor Sparkle XPC entitlements are preserved during re-signing. OpenSSL 3 is explicitly selected for Ed25519 fixtures and final verification; trusted main builds permit the committed SwiftLint plugin.
