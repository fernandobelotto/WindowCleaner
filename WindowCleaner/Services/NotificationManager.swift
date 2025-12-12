import Foundation
import os
import UserNotifications

// MARK: - Notification Manager

/// Service for managing local notifications.
///
/// Usage:
/// ```swift
/// // Request permission on app launch
/// await NotificationManager.shared.requestAuthorization()
///
/// // Send a notification
/// NotificationManager.shared.send(
///     title: "Item Created",
///     body: "Your new item has been saved."
/// )
/// ```
@Observable
final class NotificationManager: NSObject {
    // MARK: - Shared Instance

    /// Shared instance for app-wide notification management
    static let shared = NotificationManager()

    // MARK: - State

    /// Current authorization status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Whether notifications are enabled by the user in app settings
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKey.notificationsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.notificationsEnabled) }
    }

    // MARK: - Private Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    override private init() {
        super.init()
        // Set default value for notifications enabled
        if UserDefaults.standard.object(forKey: UserDefaultsKey.notificationsEnabled) == nil {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.notificationsEnabled)
        }
        notificationCenter.delegate = self
    }

    // MARK: - Authorization

    /// Requests notification authorization from the user.
    /// - Returns: Whether authorization was granted
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await updateAuthorizationStatus()
            Log.general.info("Notification authorization: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            Log.general.error("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    /// Updates the current authorization status.
    func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Checks if notifications can be sent (authorized and enabled).
    var canSendNotifications: Bool {
        authorizationStatus == .authorized && isEnabled
    }

    // MARK: - Send Notifications

    /// Sends a local notification.
    /// - Parameters:
    ///   - title: The notification title
    ///   - body: The notification body text
    ///   - subtitle: Optional subtitle
    ///   - sound: The notification sound (default: `.default`)
    ///   - delay: Delay before showing the notification in seconds (default: 0.1)
    ///   - identifier: Optional unique identifier (auto-generated if nil)
    func send(
        title: String,
        body: String,
        subtitle: String? = nil,
        sound: UNNotificationSound = .default,
        delay: TimeInterval = 0.1,
        identifier: String? = nil
    ) {
        guard canSendNotifications else {
            Log.general.debug("Notifications disabled or not authorized, skipping notification")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle {
            content.subtitle = subtitle
        }
        content.sound = sound

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(delay, 0.1),
            repeats: false
        )

        let requestIdentifier = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error {
                Log.general.error("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                Log.general.debug("Notification scheduled: \(title)")
            }
        }
    }

    /// Removes all pending notifications.
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        Log.general.debug("Removed all pending notifications")
    }

    /// Removes all delivered notifications from Notification Center.
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        Log.general.debug("Removed all delivered notifications")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banner even when app is in foreground
        completionHandler([.banner, .sound])
    }

    /// Handle user interaction with notification
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        Log.general.info("User tapped notification: \(identifier)")

        // Handle notification tap action here if needed
        // For example, navigate to specific content based on identifier

        completionHandler()
    }
}

// MARK: - Convenience Methods for Common Notifications

extension NotificationManager {
    /// Sends a notification when an item is created.
    func notifyItemCreated() {
        send(
            title: "Item Created",
            body: "Your new item has been saved successfully.",
            identifier: "item-created"
        )
    }

    /// Sends a notification when an item is deleted.
    func notifyItemDeleted() {
        send(
            title: "Item Deleted",
            body: "The item has been removed.",
            identifier: "item-deleted"
        )
    }

    /// Sends a notification when an item is duplicated.
    func notifyItemDuplicated() {
        send(
            title: "Item Duplicated",
            body: "A copy of the item has been created.",
            identifier: "item-duplicated"
        )
    }

    /// Sends a welcome notification.
    func notifyWelcome() {
        send(
            title: "Welcome to WindowCleaner!",
            body: "Thanks for using the app. Notifications are enabled.",
            subtitle: "Getting Started",
            identifier: "welcome"
        )
    }

    /// Sends a custom notification with a category.
    /// - Parameters:
    ///   - title: Notification title
    ///   - message: Notification message
    func notifyCustom(title: String, message: String) {
        send(title: title, body: message)
    }
}
