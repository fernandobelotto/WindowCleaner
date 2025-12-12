import SwiftUI

// MARK: - Window Identifiers

/// Type-safe identifiers for auxiliary windows.
enum WindowID: String {
    /// The welcome/onboarding window shown on first launch
    case welcome = "welcome-window"

    /// The In-App Purchase store window
    case store = "store-window"

    // Future windows can be added here:
    // case about = "about-window"
    // case whatsNew = "whats-new-window"
}

// MARK: - Window Manager

/// Centralized service for managing auxiliary windows.
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     @Environment(\.openWindow) private var openWindow
///
///     var body: some View {
///         Button("Show Welcome") {
///             WindowManager.openWelcome(using: openWindow)
///         }
///     }
/// }
/// ```
@Observable
final class WindowManager {
    // MARK: - Shared Instance

    /// Shared instance for tracking window state
    static let shared = WindowManager()

    // MARK: - State

    /// Whether the welcome window has been shown this session
    private(set) var hasShownWelcomeThisSession = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Window Actions

    /// Opens the welcome window.
    /// - Parameter openWindow: The openWindow environment action
    static func openWelcome(using openWindow: OpenWindowAction) {
        openWindow(id: WindowID.welcome.rawValue)
        shared.hasShownWelcomeThisSession = true
    }

    /// Dismisses the welcome window.
    /// - Parameter dismissWindow: The dismissWindow environment action
    static func dismissWelcome(using dismissWindow: DismissWindowAction) {
        dismissWindow(id: WindowID.welcome.rawValue)
    }

    /// Opens the store window.
    /// - Parameter openWindow: The openWindow environment action
    static func openStore(using openWindow: OpenWindowAction) {
        openWindow(id: WindowID.store.rawValue)
    }

    /// Dismisses the store window.
    /// - Parameter dismissWindow: The dismissWindow environment action
    static func dismissStore(using dismissWindow: DismissWindowAction) {
        dismissWindow(id: WindowID.store.rawValue)
    }

    // MARK: - First Launch Detection

    /// Checks if this is the first launch and opens the welcome window if needed.
    /// - Parameters:
    ///   - openWindow: The openWindow environment action
    ///   - showWelcomeScreen: The current value of the showWelcomeScreen preference
    static func showWelcomeIfNeeded(
        using openWindow: OpenWindowAction,
        showWelcomeScreen: Bool
    ) {
        guard showWelcomeScreen, !shared.hasShownWelcomeThisSession else { return }
        openWelcome(using: openWindow)
    }

    /// Resets the session state (useful for testing)
    func resetSessionState() {
        hasShownWelcomeThisSession = false
    }
}

// MARK: - Environment Key for WindowManager

/// Environment key for injecting WindowManager
private struct WindowManagerKey: EnvironmentKey {
    static let defaultValue = WindowManager.shared
}

extension EnvironmentValues {
    /// Access the shared WindowManager instance
    var windowManager: WindowManager {
        get { self[WindowManagerKey.self] }
        set { self[WindowManagerKey.self] = newValue }
    }
}
