#if os(macOS) && !APP_STORE
    import AppKit
    import Observation
    import Sparkle
    import SwiftUI

    @MainActor @Observable
    final class UpdateController: NSObject, SPUUpdaterDelegate {
        static let shared = UpdateController(repository: "fernandobelotto/WindowCleaner", app: "WindowCleaner")
        private(set) var checking = false
        private(set) var status: String?
        private let tokenStore: any UpdateTokenStore
        private let defaults: UserDefaults
        private let transport: PrivateUpdateTransport
        @ObservationIgnored private var controller: SPUStandardUpdaterController?
        @ObservationIgnored private var timer: Timer?
        private var cycleActive = false
        private(set) var hasPendingInstall = false
        @ObservationIgnored private var pendingInstallHandler: (() -> Void)?
        var restartGuard: @MainActor () -> Bool = { false }

        var isSafeToRestart: Bool {
            restartGuard() && !NSDocumentController.shared.hasEditedDocuments && !NSApp.windows.contains { $0.attachedSheet != nil }
        }

        init(tokenStore: (any UpdateTokenStore)? = nil, defaults: UserDefaults = .standard,
             repository: String? = nil, app: String? = nil, schedulesChecks: Bool = true) {
            self.tokenStore = tokenStore ?? KeychainUpdateTokenStore()
            self.defaults = defaults
            let name = app ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App")
            transport = PrivateUpdateTransport(repository: repository ?? "fernandobelotto/" + name, app: name)
            super.init()
            transport.failureHandler = { [weak self] error in self?.status = error.localizedDescription }
            defaults.register(defaults: ["PrivateUpdatesAutomaticChecks": true, "PrivateUpdatesAutomaticInstall": false])
            if schedulesChecks, ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
                    Task { @MainActor in self?.scheduledCheck() }
                }
                Task { @MainActor [weak self] in self?.scheduledCheck() }
            }
        }

        var automaticallyChecksForUpdates: Bool {
            get { defaults.bool(forKey: "PrivateUpdatesAutomaticChecks") }
            set { defaults.set(newValue, forKey: "PrivateUpdatesAutomaticChecks") }
        }

        var automaticallyInstallsUpdates: Bool {
            get { defaults.bool(forKey: "PrivateUpdatesAutomaticInstall") }
            set {
                defaults.set(newValue, forKey: "PrivateUpdatesAutomaticInstall")
                controller?.updater.automaticallyDownloadsUpdates = newValue
            }
        }

        var canCheckForUpdates: Bool { !checking && !hasPendingInstall && (!cycleActive || controller?.updater.canCheckForUpdates == true) }

        func scheduledCheck() {
            guard automaticallyChecksForUpdates else { return }
            checkForUpdates(userInitiated: false)
        }

        func checkForUpdates(userInitiated: Bool = true) {
            if userInitiated, cycleActive, !hasPendingInstall, controller?.updater.canCheckForUpdates == true {
                controller?.checkForUpdates(nil)
                return
            }
            guard canCheckForUpdates, !cycleActive else { return }
            checking = true
            status = nil
            Task { @MainActor in
                defer { checking = false }
                do {
                    // This repository is already public. Anonymous GitHub downloads remain supported.
                    let token = try? tokenStore.readToken()
                    try await transport.prepare(token: token) { [tokenStore] in try? tokenStore.readToken() }
                    if controller == nil {
                        let next = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil)
                        next.updater.automaticallyChecksForUpdates = false
                        next.updater.automaticallyDownloadsUpdates = automaticallyInstallsUpdates
                        try next.updater.start()
                        controller = next
                    }
                    cycleActive = true
                    if userInitiated { controller?.checkForUpdates(nil) }
                    else { controller?.updater.checkForUpdatesInBackground() }
                } catch {
                    status = error.localizedDescription
                    if userInitiated {
                        let alert = NSAlert()
                        alert.messageText = "Could Not Check for Updates"
                        alert.informativeText = error.localizedDescription
                        alert.runModal()
                    }
                }
            }
        }

        func configurePrivateUpdates() {
            let alert = NSAlert()
            alert.messageText = "Optional GitHub Access"
            alert.informativeText = "Public updates work without a token. For higher API limits, optionally use a GitHub fine-grained token limited to \(transport.repository), with Contents: Read-only. It stays in this Mac’s Keychain."
            alert.addButton(withTitle: "Save and Check")
            alert.addButton(withTitle: "Cancel")
            let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 420, height: 24))
            field.placeholderString = "GitHub personal access token"
            alert.accessoryView = field
            alert.window.initialFirstResponder = field
            guard alert.runModal() == .alertFirstButtonReturn else { field.stringValue = ""
                return
            }
            defer { field.stringValue = "" }
            do { try tokenStore.saveToken(field.stringValue)
                checkForUpdates()
            } catch { status = error.localizedDescription }
        }

        func feedURLString(for _: SPUUpdater) -> String? { transport.feedURL?.absoluteString }
        func updater(_: SPUUpdater, shouldDownloadReleaseNotesForUpdate _: SUAppcastItem) -> Bool { false }
        func updater(_: SPUUpdater, willDownloadUpdate _: SUAppcastItem, with request: NSMutableURLRequest) {
            guard request.url == transport.sourceArchiveURL, let destination = transport.archiveURL else {
                request.url = URL(string: "http://127.0.0.1:1/rejected-update")
                return
            }
            request.url = destination
            request.setValue(nil, forHTTPHeaderField: "Authorization")
            request.setValue(nil, forHTTPHeaderField: "Cookie")
        }

        func updater(_: SPUUpdater, didFinishUpdateCycleFor _: SPUUpdateCheck, error: (any Error)?) {
            cycleActive = false
            if status == nil { status = error?.localizedDescription }
        }

        func updater(_: SPUUpdater, shouldPostponeRelaunchForUpdate _: SUAppcastItem,
                     untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
            deferInstallation(installHandler)
            installDownloadedUpdate()
            return true
        }

        func deferInstallation(_ installHandler: @escaping () -> Void) {
            pendingInstallHandler = installHandler
            hasPendingInstall = true
        }

        func installDownloadedUpdate() {
            guard hasPendingInstall else { return }
            guard isSafeToRestart else {
                status = "Finish recording, active operations and unsaved work before installing this update."
                return
            }
            let alert = NSAlert()
            alert.messageText = "Restart to Install Update?"
            alert.informativeText = "Finish active operations and save your work before restarting. You can install later."
            alert.addButton(withTitle: "Restart Now")
            alert.addButton(withTitle: "Later")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            Task { @MainActor in
                guard self.isSafeToRestart, let handler = self.pendingInstallHandler else {
                    self.status = "Save your work and finish active operations before restarting."
                    return
                }
                self.pendingInstallHandler = nil
                self.hasPendingInstall = false
                handler()
            }
        }
    }

    struct PrivateUpdateSettings: View {
        @State private var updater = UpdateController.shared
        var body: some View {
            Form {
                Section("Updates") {
                    Toggle("Automatically check for updates", isOn: $updater.automaticallyChecksForUpdates)
                    Toggle("Automatically download and install updates", isOn: $updater.automaticallyInstallsUpdates)
                    Text("Installation asks before restarting so you can finish and save your work.").font(.caption)
                    Button("Optional GitHub Access…") { updater.configurePrivateUpdates() }
                    Button("Check for Updates…") { updater.checkForUpdates() }.disabled(!updater.canCheckForUpdates)

                    if updater.hasPendingInstall {
                        Button("Install Downloaded Update…") { updater.installDownloadedUpdate() }
                    }
                    if let status = updater.status { Text(status).font(.caption).foregroundStyle(.secondary) }
                }
            }.padding()
        }
    }
#endif

#if os(macOS) && !APP_STORE
    struct UpdateCommands: Commands {
        @State private var updater = UpdateController.shared
        var body: some Commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updater.checkForUpdates() }.disabled(!updater.canCheckForUpdates)
                if updater.hasPendingInstall { Button("Install Downloaded Update…") { updater.installDownloadedUpdate() } }
            }
        }
    }
#endif
