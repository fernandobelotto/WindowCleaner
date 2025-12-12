import ApplicationServices
import AppKit
import Foundation
import os

// MARK: - Permissions Manager

/// Manages system permissions required by WindowCleaner.
/// Currently handles Accessibility API access for window enumeration.
@MainActor
@Observable
final class PermissionsManager {
    // MARK: - Singleton

    static let shared = PermissionsManager()

    // MARK: - State

    /// Whether accessibility access is granted
    private(set) var hasAccessibilityAccess: Bool = false

    /// Whether the user has been prompted for accessibility access
    @ObservationIgnored
    private var hasPromptedForAccess: Bool = false

    // MARK: - Initialization

    private init() {
        checkAccessibilityAccess()
        Log.tracking.info("PermissionsManager initialized, accessibility: \(self.hasAccessibilityAccess)")
    }

    // MARK: - Public Methods

    /// Checks the current accessibility permission status.
    func checkAccessibilityAccess() {
        // Check if we have accessibility access
        // kAXTrustedCheckOptionPrompt = false means we're just checking, not prompting
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        hasAccessibilityAccess = AXIsProcessTrustedWithOptions(options)
    }

    /// Requests accessibility access by prompting the user.
    /// The system will show a dialog asking the user to grant access.
    func requestAccessibilityAccess() {
        guard !hasPromptedForAccess else {
            // Already prompted, just open System Settings
            openAccessibilitySettings()
            return
        }

        hasPromptedForAccess = true

        // This will show the system prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // Schedule a check after a delay to update our state
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                self.checkAccessibilityAccess()
            }
        }

        Log.tracking.info("Requested accessibility access")
    }

    /// Opens the System Settings app to the Accessibility pane.
    func openAccessibilitySettings() {
        // The URL scheme for Privacy & Security > Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Starts monitoring for accessibility permission changes.
    func startMonitoring() {
        // Poll for changes every 5 seconds
        Task {
            while true {
                try? await Task.sleep(for: .seconds(5))
                await MainActor.run {
                    self.checkAccessibilityAccess()
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Whether we can enumerate windows (requires accessibility access)
    var canEnumerateWindows: Bool {
        hasAccessibilityAccess
    }

    /// A human-readable status message
    var statusMessage: String {
        if hasAccessibilityAccess {
            return "Accessibility access granted"
        } else {
            return "Accessibility access required for window counting"
        }
    }
}

// MARK: - Permission Status

enum PermissionStatus: String, CaseIterable, Identifiable {
    case granted = "Granted"
    case denied = "Denied"
    case notDetermined = "Not Determined"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .granted: "checkmark.circle.fill"
        case .denied: "xmark.circle.fill"
        case .notDetermined: "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .granted: "green"
        case .denied: "red"
        case .notDetermined: "orange"
        }
    }
}
