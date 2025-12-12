import AppKit
import Combine
import Foundation
import os
import SwiftData

// MARK: - App Tracking Service

/// Service responsible for tracking running applications and their activity.
/// Observes NSWorkspace notifications to track app launches, terminations, and activations.
@MainActor
@Observable
final class AppTrackingService {
    // MARK: - Singleton

    static let shared = AppTrackingService()

    // MARK: - Published State

    /// All currently running user applications
    private(set) var runningApps: [TrackedApp] = []

    /// The currently active (frontmost) app
    private(set) var activeApp: TrackedApp?

    /// When tracking started
    private(set) var trackingStartDate: Date = Date()

    /// Whether the service is currently tracking
    private(set) var isTracking: Bool = false

    // MARK: - Private Properties

    private var workspaceObservers: [NSObjectProtocol] = []
    private var lastActiveAppId: String?
    private var lastActivationTime: Date?
    private var modelContext: ModelContext?

    // MARK: - Configuration

    /// Apps to exclude from tracking (by bundle identifier)
    private let excludedBundleIdentifiers: Set<String> = [
        "com.apple.loginwindow",
        "com.apple.dock",
        "com.apple.SystemUIServer",
        "com.apple.controlcenter",
        "com.apple.Spotlight",
        "com.apple.notificationcenterui",
    ]

    // MARK: - Initialization

    private init() {
        Log.tracking.info("AppTrackingService initialized")
    }

    // MARK: - Public Methods

    /// Starts tracking running applications
    /// - Parameter modelContext: SwiftData context for persisting usage records
    func startTracking(modelContext: ModelContext? = nil) {
        guard !isTracking else {
            Log.tracking.warning("Tracking already started")
            return
        }

        self.modelContext = modelContext
        trackingStartDate = Date()
        isTracking = true

        // Initial scan of running apps
        refreshRunningApps()

        // Set up workspace observers
        setupObservers()

        Log.tracking.info("Started tracking \(self.runningApps.count) apps")
    }

    /// Stops tracking running applications
    func stopTracking() {
        guard isTracking else { return }

        // Record final active time for current app
        if let activeId = lastActiveAppId, let activationTime = lastActivationTime {
            recordActiveTime(for: activeId, since: activationTime)
        }

        // Remove observers
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()

        isTracking = false
        Log.tracking.info("Stopped tracking")
    }

    /// Refreshes the list of running applications
    func refreshRunningApps() {
        let workspace = NSWorkspace.shared
        let apps = workspace.runningApplications

        // Keep track of existing apps to preserve their metrics
        let existingAppsById = Dictionary(uniqueKeysWithValues: runningApps.map { ($0.id, $0) })

        var updatedApps: [TrackedApp] = []

        for app in apps {
            // Skip apps without a bundle identifier
            guard let bundleId = app.bundleIdentifier else { continue }

            // Skip excluded apps
            guard !excludedBundleIdentifiers.contains(bundleId) else { continue }

            // Skip non-regular apps (agents, background apps without UI)
            guard app.activationPolicy == .regular else { continue }

            let appId = "\(bundleId).\(app.processIdentifier)"

            if let existing = existingAppsById[appId] {
                // Update existing app's dynamic properties
                existing.isHidden = app.isHidden
                existing.isActive = app.isActive
                updatedApps.append(existing)
            } else {
                // Create new tracked app
                let trackedApp = TrackedApp(from: app)
                trackedApp.isActive = app.isActive
                updatedApps.append(trackedApp)

                // Record launch in usage history
                recordLaunch(for: trackedApp)
            }
        }

        // Update active app reference
        activeApp = updatedApps.first { $0.isActive }

        runningApps = updatedApps
    }

    /// Updates metrics for all running apps
    /// Called by ProcessMonitor on each polling cycle
    func updateMetrics(for appId: String, memory: UInt64, cpu: Double, windowCount: Int) {
        guard let app = runningApps.first(where: { $0.id == appId }) else { return }

        app.memoryUsage = memory
        app.cpuUsage = cpu
        app.windowCount = windowCount

        // Update usage record with memory stats
        updateUsageRecord(for: app)
    }

    /// Quits an application gracefully
    /// - Parameter app: The app to quit
    /// - Returns: True if the quit request was sent
    @discardableResult
    func quitApp(_ app: TrackedApp) -> Bool {
        guard app.quit() else { return false }

        // Record quit in usage history
        recordQuit(for: app)

        return true
    }

    /// Quits multiple applications
    /// - Parameter apps: The apps to quit
    /// - Returns: Number of apps that received quit requests
    func quitApps(_ apps: [TrackedApp]) -> Int {
        var count = 0
        for app in apps where !app.isProtected && !app.isSystemApp {
            if quitApp(app) {
                count += 1
            }
        }
        return count
    }

    /// Gets or creates the usage record for an app for today
    func usageRecord(for app: TrackedApp) -> AppUsageRecord? {
        guard let context = modelContext else { return nil }

        let today = Calendar.current.startOfDay(for: Date())
        let bundleId = app.bundleIdentifier

        // Try to find existing record
        var descriptor = FetchDescriptor<AppUsageRecord>(
            predicate: #Predicate { record in
                record.bundleIdentifier == bundleId && record.date == today
            }
        )
        descriptor.fetchLimit = 1

        do {
            let records = try context.fetch(descriptor)
            if let existing = records.first {
                return existing
            }

            // Create new record
            let record = AppUsageRecord(
                bundleIdentifier: bundleId,
                appName: app.name,
                date: today
            )
            context.insert(record)
            return record
        } catch {
            Log.tracking.error("Failed to fetch/create usage record: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        let nc = NSWorkspace.shared.notificationCenter

        // App activated (became frontmost)
        let activateObserver = nc.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            // Extract data synchronously on main queue
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self.handleAppActivatedSync(app)
        }
        workspaceObservers.append(activateObserver)

        // App launched
        let launchObserver = nc.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self.handleAppLaunchedSync(app)
        }
        workspaceObservers.append(launchObserver)

        // App terminated
        let terminateObserver = nc.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self.handleAppTerminatedSync(app)
        }
        workspaceObservers.append(terminateObserver)

        // App hidden
        let hideObserver = nc.addObserver(
            forName: NSWorkspace.didHideApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self.handleAppHiddenSync(app)
        }
        workspaceObservers.append(hideObserver)

        // App unhidden
        let unhideObserver = nc.addObserver(
            forName: NSWorkspace.didUnhideApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self.handleAppUnhiddenSync(app)
        }
        workspaceObservers.append(unhideObserver)
    }

    private nonisolated func handleAppActivatedSync(_ app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier,
              !excludedBundleIdentifiers.contains(bundleId)
        else { return }

        MainActor.assumeIsolated {
            handleAppActivatedMain(app, bundleId: bundleId)
        }
    }

    private func handleAppActivatedMain(_ app: NSRunningApplication, bundleId: String) {

        let appId = "\(bundleId).\(app.processIdentifier)"

        // Record active time for previously active app
        if let previousId = lastActiveAppId,
           previousId != appId,
           let activationTime = lastActivationTime
        {
            recordActiveTime(for: previousId, since: activationTime)
        }

        // Update last active date for the newly activated app
        if let trackedApp = runningApps.first(where: { $0.id == appId }) {
            trackedApp.lastActiveDate = Date()
            trackedApp.isActive = true

            // Record activation
            if let record = usageRecord(for: trackedApp) {
                record.recordActivation()
                saveContext()
            }
        }

        // Update active states
        for trackedApp in runningApps {
            trackedApp.isActive = trackedApp.id == appId
        }

        activeApp = runningApps.first { $0.id == appId }
        lastActiveAppId = appId
        lastActivationTime = Date()

        Log.tracking.debug("App activated: \(app.localizedName ?? "unknown")")
    }

    private nonisolated func handleAppLaunchedSync(_ app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier,
              !excludedBundleIdentifiers.contains(bundleId),
              app.activationPolicy == .regular
        else { return }

        MainActor.assumeIsolated {
            let trackedApp = TrackedApp(from: app, launchDate: Date())
            runningApps.append(trackedApp)
            recordLaunch(for: trackedApp)
            Log.tracking.info("App launched: \(app.localizedName ?? "unknown")")
        }
    }

    private nonisolated func handleAppTerminatedSync(_ app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier else { return }

        let appId = "\(bundleId).\(app.processIdentifier)"

        MainActor.assumeIsolated {
            // Record final active time if this was the active app
            if lastActiveAppId == appId, let activationTime = lastActivationTime {
                recordActiveTime(for: appId, since: activationTime)
                lastActiveAppId = nil
                lastActivationTime = nil
            }

            // Remove from tracked apps
            runningApps.removeAll { $0.id == appId }

            if activeApp?.id == appId {
                activeApp = nil
            }

            Log.tracking.info("App terminated: \(app.localizedName ?? "unknown")")
        }
    }

    private nonisolated func handleAppHiddenSync(_ app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier else { return }

        let appId = "\(bundleId).\(app.processIdentifier)"

        MainActor.assumeIsolated {
            if let trackedApp = runningApps.first(where: { $0.id == appId }) {
                trackedApp.isHidden = true
            }
        }
    }

    private nonisolated func handleAppUnhiddenSync(_ app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier else { return }

        let appId = "\(bundleId).\(app.processIdentifier)"

        MainActor.assumeIsolated {
            if let trackedApp = runningApps.first(where: { $0.id == appId }) {
                trackedApp.isHidden = false
            }
        }
    }

    // MARK: - Usage Recording

    private func recordLaunch(for app: TrackedApp) {
        guard let record = usageRecord(for: app) else { return }
        record.recordLaunch()
        saveContext()
    }

    private func recordQuit(for app: TrackedApp) {
        guard let record = usageRecord(for: app) else { return }
        record.recordQuit()
        saveContext()
    }

    private func recordActiveTime(for appId: String, since startTime: Date) {
        guard let app = runningApps.first(where: { $0.id == appId }),
              let record = usageRecord(for: app)
        else { return }

        let duration = Date().timeIntervalSince(startTime)
        record.addActiveTime(duration)
        saveContext()
    }

    private func updateUsageRecord(for app: TrackedApp) {
        guard let record = usageRecord(for: app) else { return }
        record.updateMemory(current: app.memoryUsage)
        // Note: We don't save on every update to avoid excessive I/O
        // Context will be saved periodically or on significant events
    }

    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            Log.tracking.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}

// MARK: - Convenience Computed Properties

extension AppTrackingService {
    /// Total memory used by all tracked apps
    var totalMemoryUsage: UInt64 {
        runningApps.reduce(0) { $0 + $1.memoryUsage }
    }

    /// Formatted total memory usage
    var formattedTotalMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalMemoryUsage), countStyle: .memory)
    }

    /// Number of tracked apps
    var appCount: Int {
        runningApps.count
    }

    /// Apps sorted by staleness score (highest first)
    var appsByStaleness: [TrackedApp] {
        runningApps.sorted { ($0 as TrackedApp).timeSinceActive > ($1 as TrackedApp).timeSinceActive }
    }

    /// Apps sorted by memory usage (highest first)
    var appsByMemory: [TrackedApp] {
        runningApps.sorted { $0.memoryUsage > $1.memoryUsage }
    }

    /// Apps sorted by CPU usage (highest first)
    var appsByCPU: [TrackedApp] {
        runningApps.sorted { $0.cpuUsage > $1.cpuUsage }
    }
}
