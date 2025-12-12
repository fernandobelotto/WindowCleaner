import SwiftUI

// MARK: - Application Configuration

/// Application-wide configuration constants.
enum Config {
    /// Current app version from Info.plist
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    /// Current build number from Info.plist
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    /// Full version string (e.g., "1.0 (42)")
    static var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }

    /// Whether the app is running in DEBUG mode
    #if DEBUG
        static let isDebug = true
    #else
        static let isDebug = false
    #endif

    /// Whether the app is running in a preview context
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    /// Whether the app is running UI tests
    static var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }
}

// MARK: - Layout Metrics

/// Standard layout measurements for consistent UI.
enum Metrics {
    // MARK: Sidebar

    /// Minimum sidebar width
    static let sidebarMinWidth: CGFloat = 180

    /// Ideal sidebar width
    static let sidebarIdealWidth: CGFloat = 220

    /// Maximum sidebar width
    static let sidebarMaxWidth: CGFloat = 300

    // MARK: Spacing

    /// Extra small spacing (4pt)
    static let spacingXS: CGFloat = 4

    /// Small spacing (8pt)
    static let spacingS: CGFloat = 8

    /// Medium spacing (16pt)
    static let spacingM: CGFloat = 16

    /// Large spacing (24pt)
    static let spacingL: CGFloat = 24

    /// Extra large spacing (32pt)
    static let spacingXL: CGFloat = 32

    // MARK: Corner Radius

    /// Small corner radius (4pt)
    static let cornerRadiusS: CGFloat = 4

    /// Medium corner radius (8pt)
    static let cornerRadiusM: CGFloat = 8

    /// Large corner radius (12pt)
    static let cornerRadiusL: CGFloat = 12

    // MARK: Icons

    /// Standard icon size
    static let iconSize: CGFloat = 24

    /// Small icon size
    static let iconSizeS: CGFloat = 16

    /// Large icon size
    static let iconSizeL: CGFloat = 32

    // MARK: Animation

    /// Standard animation duration
    static let animationDuration: Double = 0.3

    /// Fast animation duration
    static let animationFast: Double = 0.15

    /// Slow animation duration
    static let animationSlow: Double = 0.5
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a new item should be created
    static let createNewItem = Notification.Name("createNewItem")

    /// Posted when the selected item should be deleted
    static let deleteSelectedItem = Notification.Name("deleteSelectedItem")

    /// Posted when the selected item should be duplicated
    static let duplicateSelectedItem = Notification.Name("duplicateSelectedItem")

    /// Posted to toggle the sidebar visibility
    static let toggleSidebar = Notification.Name("toggleSidebar")

    /// Posted to refresh the current view
    static let refreshContent = Notification.Name("refreshContent")

    /// Posted to clear all data (DEBUG only)
    static let clearAllData = Notification.Name("clearAllData")

    // Note: Welcome window is now managed via WindowManager.openWelcome()
}

// MARK: - User Defaults Keys

/// Keys for UserDefaults / @AppStorage
enum UserDefaultsKey {
    static let showWelcomeScreen = "showWelcomeScreen"
    static let sidebarWidth = "sidebarWidth"
    static let lastSelectedItemID = "lastSelectedItemID"

    /// Last seen app version (for "What's New" feature)
    static let lastSeenVersion = "lastSeenVersion"

    /// Whether notifications are enabled
    static let notificationsEnabled = "notificationsEnabled"
}
