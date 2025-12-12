import os
import StoreKit
import SwiftData
import SwiftUI

// MARK: - App Entry Point

@main
struct MacAppTemplateApp: App {
    // MARK: - Store Manager

    /// Shared store manager for In-App Purchases
    private var storeManager = StoreManager.shared

    // MARK: - Model Container

    var sharedModelContainer: ModelContainer = {
        do {
            return try DataService.makeContainer()
        } catch {
            Log.data.critical("Container creation failed: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        // Main Window
        WindowGroup {
            MainContentView()
                .frame(minWidth: 600, minHeight: 400)
                .environment(storeManager)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            appCommands
        }

        // Welcome Window (standalone auxiliary window)
        Window("Welcome to MacAppTemplate", id: WindowID.welcome.rawValue) {
            WelcomeView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)

        // Store Window
        Window("Store", id: WindowID.store.rawValue) {
            StoreView()
                .environment(storeManager)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Settings Window (⌘,)
        Settings {
            SettingsView()
                .environment(storeManager)
        }
    }

    // MARK: - Commands

    @CommandsBuilder private var appCommands: some Commands {
        // File Menu Commands - Replace default "New Window" with "New Item"
        CommandGroup(replacing: .newItem) {
            Button("New Item") {
                NotificationCenter.default.post(name: .createNewItem, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        // Edit Menu Commands
        CommandGroup(after: .pasteboard) {
            Button("Duplicate") {
                NotificationCenter.default.post(name: .duplicateSelectedItem, object: nil)
            }
            .keyboardShortcut("d", modifiers: .command)

            Button("Delete") {
                NotificationCenter.default.post(name: .deleteSelectedItem, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: [])
        }

        // View Menu Commands
        ViewCommands()

        // Store Menu Commands
        StoreCommands()

        // Help Menu - Show Welcome
        ShowWelcomeCommands()

        // Help Menu
        CommandGroup(replacing: .help) {
            if let docsURL = URL(string: "https://github.com/fernandobelotto/MacAppTemplate") {
                Link("MacAppTemplate Documentation", destination: docsURL)
            }

            Divider()

            if let issuesURL = URL(string: "https://github.com/fernandobelotto/MacAppTemplate/issues") {
                Link("Report an Issue", destination: issuesURL)
            }
        }

        // Debug Menu (only in DEBUG builds)
        #if DEBUG
            DebugCommands()
        #endif
    }
}

// MARK: - View Commands

/// Commands for the View menu.
struct ViewCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button("Refresh") {
                NotificationCenter.default.post(name: .refreshContent, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            Button("Toggle Sidebar") {
                NotificationCenter.default.post(name: .toggleSidebar, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
    }
}

// MARK: - Debug Commands

#if DEBUG
    /// Debug menu commands (only available in DEBUG builds).
    struct DebugCommands: Commands {
        var body: some Commands {
            CommandMenu("Debug") {
                Button("Print App State") {
                    Log.general.debug("Debug: App state printed")
                    Log.general.debug("Version: \(Config.fullVersion)")
                    Log.general.debug("Is Preview: \(Config.isPreview)")
                    Log.general.debug("Is UI Testing: \(Config.isUITesting)")
                }
                .keyboardShortcut("p", modifiers: [.command, .option])

                Divider()

                Button("Send Test Notification") {
                    NotificationManager.shared.notifyCustom(
                        title: "Debug Notification",
                        message: "This is a test notification from the Debug menu."
                    )
                }
                .keyboardShortcut("n", modifiers: [.command, .option])

                Divider()

                Button("Simulate Error") {
                    Log.general.error("Debug: Simulated error triggered")
                }

                Divider()

                Button("Clear All Data") {
                    NotificationCenter.default.post(name: .clearAllData, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .option])

                Button("Reset Preferences") {
                    if let bundleId = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleId)
                        UserDefaults.standard.synchronize()
                        Log.general.info("Debug: All preferences reset")
                        NotificationManager.shared.notifyCustom(
                            title: "Preferences Reset",
                            message: "All user preferences have been cleared."
                        )
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .option])

                Button("Reset Payments") {
                    Task {
                        await StoreManager.shared.resetForTesting()
                        Log.general.info("Debug: Payments reset")
                        NotificationManager.shared.notifyCustom(
                            title: "Payments Reset",
                            message: "Local store state cleared. Use Xcode > Debug > StoreKit to clear sandbox."
                        )
                    }
                }
                .keyboardShortcut("y", modifiers: [.command, .option])
            }
        }
    }
#endif

// MARK: - Store Commands

/// Commands for accessing the Store from the menu bar.
struct StoreCommands: Commands {
    @Environment(\.openWindow)
    private var openWindow

    var body: some Commands {
        CommandGroup(after: .appSettings) {
            Button("Store...") {
                WindowManager.openStore(using: openWindow)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Divider()
        }
    }
}

// MARK: - Show Welcome Commands

/// Commands for showing the Welcome window from the Help menu.
struct ShowWelcomeCommands: Commands {
    @Environment(\.openWindow)
    private var openWindow

    var body: some Commands {
        CommandGroup(before: .help) {
            Button("Show Welcome") {
                WindowManager.openWelcome(using: openWindow)
            }

            Divider()
        }
    }
}

// MARK: - Main Content View

/// Wrapper view that handles welcome screen presentation.
struct MainContentView: View {
    @Environment(\.openWindow)
    private var openWindow

    @AppStorage(UserDefaultsKey.showWelcomeScreen)
    private var showWelcomeScreen = true

    var body: some View {
        ContentView()
            .onAppear {
                // Show welcome on first launch (skip during UI testing)
                if !Config.isUITesting {
                    WindowManager.showWelcomeIfNeeded(
                        using: openWindow,
                        showWelcomeScreen: showWelcomeScreen
                    )
                }
            }
            .task {
                // Request notification authorization on first launch
                await NotificationManager.shared.requestAuthorization()
            }
    }
}
