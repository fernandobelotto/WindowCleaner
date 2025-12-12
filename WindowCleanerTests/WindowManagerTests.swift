@testable import WindowCleaner
import Testing

// MARK: - WindowManager Tests

/// Tests for the `WindowManager` service.
struct WindowManagerTests {
    // MARK: - Session State Tests

    @Test("hasShownWelcomeThisSession starts as false", .tags(.service))
    @MainActor
    func hasShownWelcomeStartsFalse() {
        let manager = WindowManager.shared
        manager.resetSessionState()

        #expect(manager.hasShownWelcomeThisSession == false)
    }

    @Test("resetSessionState resets hasShownWelcomeThisSession", .tags(.service))
    @MainActor
    func resetSessionStateResetsFlag() {
        let manager = WindowManager.shared

        // We can't directly set hasShownWelcomeThisSession, but we can reset it
        manager.resetSessionState()

        #expect(manager.hasShownWelcomeThisSession == false)
    }

    // MARK: - Window ID Tests

    @Test("WindowID welcome has correct raw value", .tags(.service))
    func windowIDWelcomeHasCorrectRawValue() {
        #expect(WindowID.welcome.rawValue == "welcome-window")
    }

    // MARK: - Shared Instance Tests

    @Test("WindowManager shared instance is consistent", .tags(.service))
    @MainActor
    func sharedInstanceIsConsistent() {
        let instance1 = WindowManager.shared
        let instance2 = WindowManager.shared

        // Both references should point to the same instance
        #expect(instance1 === instance2)
    }
}
