#if !APP_STORE
    import Foundation
    import Testing
    #if !UPDATER_TEST_HARNESS
        @testable import WindowCleaner
    #endif

    @MainActor
    struct UpdateTests {
        final class Tokens: UpdateTokenStore {
            var value: String?
            func readToken() throws -> String? { value }
            func saveToken(_ token: String) throws { value = token }
        }

        @Test
        func tokensRejectWhitespaceAndMissingAccess() {
            #expect(PrivateUpdateAccess.validToken("github_pat_abc123"))
            for token in ["", "github pat", "token\n", "token\r", "é"] {
                #expect(!PrivateUpdateAccess.validToken(token))
            }
            #expect(Tokens().value == nil)
        }

        @Test
        func restartIsDeniedUntilLifecycleGuardAllowsIt() {
            let updater = UpdateController(
                tokenStore: Tokens(),
                repository: "fernandobelotto/WindowCleaner",
                app: "WindowCleaner",
                schedulesChecks: false
            )
            #expect(!updater.isSafeToRestart)
            updater.restartGuard = { false }
            #expect(!updater.isSafeToRestart)
        }

        @Test
        func unsafeInstallRetainsPendingHandlerWithoutRestarting() {
            let updater = UpdateController(tokenStore: Tokens(), schedulesChecks: false)
            var restarted = false
            updater.deferInstallation { restarted = true }
            updater.restartGuard = { false }
            updater.installDownloadedUpdate()
            #expect(updater.hasPendingInstall)
            #expect(!updater.canCheckForUpdates)
            #expect(!restarted)
        }

        @Test
        func checkAndInstallPreferencesPersistIndependently() throws {
            let suite = "update-tests-" + UUID().uuidString
            let defaults = try #require(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let updater = UpdateController(tokenStore: Tokens(), defaults: defaults, schedulesChecks: false)
            updater.automaticallyChecksForUpdates = false
            updater.automaticallyInstallsUpdates = true
            let restored = UpdateController(tokenStore: Tokens(), defaults: defaults, schedulesChecks: false)
            #expect(!restored.automaticallyChecksForUpdates)
            #expect(restored.automaticallyInstallsUpdates)
        }

        @Test
        func incompleteDraftAndPrereleaseArtifactsAreIgnored() throws {
            let json = #"[{"id":1,"tag_name":"v1.0.0","draft":false,"prerelease":false,"assets":[{"id":2,"name":"appcast.xml","size":100,"state":"uploaded"},{"id":3,"name":"release.json","size":100,"state":"uploaded"},{"id":4,"name":"WindowCleaner-1.0.0-universal.zip","size":100,"state":"uploaded"}]}]"#
            let release = try JSONDecoder().decode([PrivateUpdateRelease].self, from: Data(json.utf8))[0]
            #expect(release.completeArchive(app: "WindowCleaner")?.id == 4)
            for value in ["draft", "prerelease"] {
                let modified = json.replacingOccurrences(of: "\"" + value + "\":false", with: "\"" + value + "\":true")
                let parsed = try JSONDecoder().decode([PrivateUpdateRelease].self, from: Data(modified.utf8))[0]
                #expect(parsed.completeArchive(app: "WindowCleaner") == nil)
            }
            let incompleteUpload = json.replacingOccurrences(of: "uploaded", with: "starter")
            let pending = try JSONDecoder().decode([PrivateUpdateRelease].self, from: Data(incompleteUpload.utf8))[0]
            #expect(pending.completeArchive(app: "WindowCleaner") == nil)
            for asset in ["appcast.xml", "release.json", "WindowCleaner-1.0.0-universal.zip"] {
                let modified = json.replacingOccurrences(of: asset, with: "missing")
                let parsed = try JSONDecoder().decode([PrivateUpdateRelease].self, from: Data(modified.utf8))[0]
                #expect(parsed.completeArchive(app: "WindowCleaner") == nil)
            }
        }

        @Test
        func malformedFeedAndMissingSignatureAreRejected() {
            let asset = PrivateUpdateRelease.Asset(id: 4, name: "WindowCleaner-1.0.0-universal.zip", size: 10)
            for xml in [
                "bad XML",
                "<rss><enclosure url='https://evil.example/archive.zip' length='10'/></rss>",
                "<rss/>",
            ] {
                #expect(throws: (any Error).self) { try UpdateFeedValidator.validate(
                    Data(xml.utf8),
                    asset: asset,
                    repository: "fernandobelotto/WindowCleaner"
                ) }
            }
        }
    }
#endif
