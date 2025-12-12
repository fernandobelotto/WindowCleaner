import AppKit
import Foundation
import os

// MARK: - Tracked App

/// Represents a currently running application with its metrics.
/// This is a runtime model (not persisted) that holds real-time information
/// about running applications.
@Observable
final class TrackedApp: Identifiable, Hashable {
    // MARK: - Properties

    /// Unique identifier based on bundle identifier and PID
    let id: String

    /// The app's bundle identifier
    let bundleIdentifier: String

    /// The app's display name
    let name: String

    /// The app's localized name (if different from name)
    let localizedName: String?

    /// Process ID
    let pid: pid_t

    /// The app's icon
    let icon: NSImage

    /// Reference to the NSRunningApplication
    let runningApplication: NSRunningApplication

    /// Current memory usage in bytes
    var memoryUsage: UInt64 = 0

    /// Current CPU usage percentage (0-100)
    var cpuUsage: Double = 0

    /// Number of windows belonging to this app
    var windowCount: Int = 0

    /// When this app was last the active (frontmost) app
    var lastActiveDate: Date

    /// When this app was launched
    let launchDate: Date

    /// Whether this app is currently the frontmost app
    var isActive: Bool = false

    /// Whether this app is hidden
    var isHidden: Bool

    /// Whether this is a system app that should be protected
    var isSystemApp: Bool

    /// Whether user has marked this app as protected
    var isProtected: Bool = false

    // MARK: - Computed Properties

    /// Memory usage formatted as a human-readable string
    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .memory)
    }

    /// CPU usage formatted as a percentage string
    var formattedCPU: String {
        String(format: "%.1f%%", cpuUsage)
    }

    /// Time since this app was last active
    var timeSinceActive: TimeInterval {
        Date().timeIntervalSince(lastActiveDate)
    }

    /// Time since this app was launched
    var uptime: TimeInterval {
        Date().timeIntervalSince(launchDate)
    }

    /// Formatted time since last active
    var formattedTimeSinceActive: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastActiveDate, relativeTo: Date())
    }

    /// Formatted uptime
    var formattedUptime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: uptime) ?? "0m"
    }

    // MARK: - Initialization

    /// Creates a TrackedApp from an NSRunningApplication
    /// - Parameters:
    ///   - app: The running application
    ///   - launchDate: When the app was launched (defaults to now if unknown)
    init(from app: NSRunningApplication, launchDate: Date? = nil) {
        self.runningApplication = app
        self.pid = app.processIdentifier
        self.bundleIdentifier = app.bundleIdentifier ?? "unknown.\(app.processIdentifier)"
        self.id = "\(bundleIdentifier).\(pid)"

        self.name = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
        self.localizedName = app.localizedName
        self.icon = app.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)
            ?? NSImage()
        self.isHidden = app.isHidden
        self.launchDate = launchDate ?? Date()
        self.lastActiveDate = Date()

        // Determine if this is a system app
        self.isSystemApp = Self.isSystemApplication(bundleIdentifier: bundleIdentifier)
    }

    // MARK: - Hashable

    static func == (lhs: TrackedApp, rhs: TrackedApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Actions

    /// Attempts to gracefully quit the application
    /// - Returns: True if the terminate request was sent successfully
    @discardableResult
    func quit() -> Bool {
        guard !isProtected, !isSystemApp else {
            Log.tracking.warning("Cannot quit protected/system app: \(self.name)")
            return false
        }
        Log.tracking.info("Requesting quit for app: \(self.name)")
        return runningApplication.terminate()
    }

    /// Brings the application to the foreground
    func activate() {
        runningApplication.activate()
    }

    /// Hides the application
    func hide() {
        runningApplication.hide()
    }

    // MARK: - Private Helpers

    /// Checks if the given bundle identifier belongs to a system app
    private static func isSystemApplication(bundleIdentifier: String) -> Bool {
        let systemPrefixes = [
            "com.apple.finder",
            "com.apple.dock",
            "com.apple.SystemUIServer",
            "com.apple.controlcenter",
            "com.apple.notificationcenterui",
            "com.apple.Spotlight",
            "com.apple.WindowManager",
        ]

        let systemContains = [
            "com.apple.loginwindow",
            "com.apple.coreservices",
        ]

        if systemPrefixes.contains(bundleIdentifier) {
            return true
        }

        for pattern in systemContains where bundleIdentifier.contains(pattern) {
            return true
        }

        return false
    }
}

// MARK: - Sorting

extension TrackedApp {
    /// Sort options for tracked apps
    enum SortOption: String, CaseIterable, Identifiable {
        case staleness = "Staleness"
        case memory = "Memory"
        case cpu = "CPU"
        case lastActive = "Last Active"
        case name = "Name"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .staleness: "clock.badge.exclamationmark"
            case .memory: "memorychip"
            case .cpu: "cpu"
            case .lastActive: "clock"
            case .name: "textformat"
            }
        }
    }

    /// Filter options for tracked apps
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All Apps"
        case stale = "Stale"
        case heavy = "Heavy"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .all: "square.grid.2x2"
            case .stale: "clock.badge.exclamationmark"
            case .heavy: "scalemass"
            }
        }
    }
}

// MARK: - Sample Data

extension TrackedApp {
    /// Creates sample tracked apps for previews
    static func sampleApps() -> [TrackedApp] {
        // In preview, we can't get real running apps, so return empty
        // Real apps will be populated by AppTrackingService
        []
    }
}
