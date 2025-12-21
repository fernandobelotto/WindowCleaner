import Foundation
import os
import SwiftData

// MARK: - App Tracking View Model

/// View model for managing the app tracking UI state.
/// Coordinates between AppTrackingService, ProcessMonitor, and StalenessCalculator.
@MainActor
@Observable
final class AppTrackingViewModel {
    // MARK: - Services

    private let trackingService: AppTrackingService
    private let processMonitor: ProcessMonitor
    private let stalenessCalculator: StalenessCalculator

    // MARK: - State

    /// Currently selected app
    var selectedApp: TrackedApp?

    /// Current filter option
    var filterOption: TrackedApp.FilterOption = .all

    /// Current sort option
    var sortOption: TrackedApp.SortOption = .staleness

    /// Sort in ascending order
    var sortAscending: Bool = false

    /// Search query for filtering apps
    var searchQuery: String = ""

    /// Whether a cleanup operation is in progress
    var isCleaningUp: Bool = false

    /// Error message to display
    var errorMessage: String?

    /// Whether to show the cleanup confirmation dialog
    var showCleanupConfirmation: Bool = false

    /// Apps pending cleanup (for confirmation)
    var pendingCleanupApps: [TrackedApp] = []

    /// Whether the cleanup selection sheet is shown
    var showCleanupSelectionSheet: Bool = false

    /// Set of app IDs selected for cleanup
    var selectedCleanupApps: Set<String> = []

    // MARK: - Initialization

    @MainActor
    init(
        trackingService: AppTrackingService? = nil,
        processMonitor: ProcessMonitor? = nil,
        stalenessCalculator: StalenessCalculator? = nil
    ) {
        self.trackingService = trackingService ?? AppTrackingService.shared
        self.processMonitor = processMonitor ?? ProcessMonitor.shared
        self.stalenessCalculator = stalenessCalculator ?? StalenessCalculator.shared
    }

    // MARK: - Computed Properties

    /// All running apps from the tracking service
    var allApps: [TrackedApp] {
        trackingService.runningApps
    }

    /// Filtered and sorted apps for display
    var displayedApps: [TrackedApp] {
        var apps = allApps

        // Apply search filter
        if !searchQuery.isEmpty {
            apps = apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchQuery)
                    || app.bundleIdentifier.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply filter option
        switch filterOption {
        case .all:
            break
        case .stale:
            apps = apps.filter(\.isStale)
        case .heavy:
            // Heavy = top 25% by memory usage
            let threshold = apps.map(\.memoryUsage).sorted().dropFirst(apps.count * 3 / 4).first ?? 0
            apps = apps.filter { $0.memoryUsage >= threshold }
        }

        // Apply sorting
        apps = sortApps(apps)

        return apps
    }

    /// Number of stale apps
    var staleAppCount: Int {
        allApps.filter(\.isStale).count
    }

    /// Total memory used by all apps
    var totalMemoryUsage: UInt64 {
        trackingService.totalMemoryUsage
    }

    /// Formatted total memory
    var formattedTotalMemory: String {
        trackingService.formattedTotalMemory
    }

    /// Potential memory savings from closing stale apps
    var potentialSavings: String {
        stalenessCalculator.formattedPotentialSavings(from: allApps)
    }

    /// System memory info
    var systemMemory: SystemMemoryInfo {
        processMonitor.systemMemory
    }

    /// Whether tracking is active
    var isTracking: Bool {
        trackingService.isTracking
    }

    /// The currently active app
    var activeApp: TrackedApp? {
        trackingService.activeApp
    }

    // MARK: - Cleanup Selection Computed Properties

    /// Memory that would be freed based on current selection
    var selectedCleanupMemory: UInt64 {
        pendingCleanupApps
            .filter { selectedCleanupApps.contains($0.id) }
            .reduce(0) { $0 + $1.memoryUsage }
    }

    /// Formatted memory savings for selected apps
    var formattedSelectedCleanupMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(selectedCleanupMemory), countStyle: .memory)
    }

    /// Number of selected apps for cleanup
    var selectedCleanupCount: Int {
        selectedCleanupApps.count
    }

    /// Whether all cleanup apps are selected
    var allCleanupAppsSelected: Bool {
        !pendingCleanupApps.isEmpty && selectedCleanupApps.count == pendingCleanupApps.count
    }

    // MARK: - Actions

    /// Starts tracking apps
    func startTracking(modelContext: ModelContext) {
        trackingService.startTracking(modelContext: modelContext)
        processMonitor.startMonitoring(trackingService: trackingService)
        Log.tracking.info("ViewModel started tracking")
    }

    /// Stops tracking apps
    func stopTracking() {
        processMonitor.stopMonitoring()
        trackingService.stopTracking()
        Log.tracking.info("ViewModel stopped tracking")
    }

    /// Refreshes the list of running apps
    func refresh() {
        trackingService.refreshRunningApps()
        processMonitor.updateAllMetrics()
    }

    /// Quits a single app
    func quitApp(_ app: TrackedApp) {
        guard !app.isProtected, !app.isSystemApp else {
            errorMessage = "Cannot quit protected or system apps"
            return
        }

        if trackingService.quitApp(app) {
            Log.tracking.info("Quit app: \(app.name)")
        } else {
            errorMessage = "Failed to quit \(app.name)"
        }
    }

    /// Prepares to clean up stale apps (shows selection sheet)
    func prepareCleanup() {
        pendingCleanupApps = stalenessCalculator.staleApps(from: allApps)

        if pendingCleanupApps.isEmpty {
            errorMessage = "No stale apps to clean up"
            return
        }

        // Pre-select all stale apps by default
        selectedCleanupApps = Set(pendingCleanupApps.map(\.id))
        showCleanupSelectionSheet = true
    }

    /// Executes the cleanup of selected apps only
    func executeCleanup() {
        let appsToQuit = pendingCleanupApps.filter { selectedCleanupApps.contains($0.id) }

        guard !appsToQuit.isEmpty else {
            cancelCleanup()
            return
        }

        isCleaningUp = true

        let count = trackingService.quitApps(appsToQuit)
        Log.tracking.info("Cleaned up \(count) apps")

        pendingCleanupApps = []
        selectedCleanupApps = []
        isCleaningUp = false
        showCleanupSelectionSheet = false
        showCleanupConfirmation = false
    }

    /// Cancels the pending cleanup
    func cancelCleanup() {
        pendingCleanupApps = []
        selectedCleanupApps = []
        showCleanupSelectionSheet = false
        showCleanupConfirmation = false
    }

    // MARK: - Cleanup Selection Actions

    /// Toggles selection for a single app
    func toggleCleanupSelection(for app: TrackedApp) {
        if selectedCleanupApps.contains(app.id) {
            selectedCleanupApps.remove(app.id)
        } else {
            selectedCleanupApps.insert(app.id)
        }
    }

    /// Checks if an app is selected for cleanup
    func isSelectedForCleanup(_ app: TrackedApp) -> Bool {
        selectedCleanupApps.contains(app.id)
    }

    /// Selects all apps for cleanup
    func selectAllForCleanup() {
        selectedCleanupApps = Set(pendingCleanupApps.map(\.id))
    }

    /// Deselects all apps for cleanup
    func selectNoneForCleanup() {
        selectedCleanupApps.removeAll()
    }

    /// Toggles protection status for an app
    func toggleProtection(for app: TrackedApp) {
        app.isProtected.toggle()
        Log.tracking.info("\(app.name) protection: \(app.isProtected)")
    }

    /// Selects an app
    func selectApp(_ app: TrackedApp?) {
        selectedApp = app
    }

    /// Clears the error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Sorting

    private func sortApps(_ apps: [TrackedApp]) -> [TrackedApp] {
        let sorted: [TrackedApp]

        switch sortOption {
        case .staleness:
            sorted = apps.sorted { $0.stalenessScore > $1.stalenessScore }
        case .memory:
            sorted = apps.sorted { $0.memoryUsage > $1.memoryUsage }
        case .cpu:
            sorted = apps.sorted { $0.cpuUsage > $1.cpuUsage }
        case .lastActive:
            sorted = apps.sorted { $0.timeSinceActive > $1.timeSinceActive }
        case .name:
            sorted = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return sortAscending ? sorted.reversed() : sorted
    }
}

// MARK: - Environment Key

import SwiftUI

private struct AppTrackingViewModelKey: EnvironmentKey {
    static let defaultValue: AppTrackingViewModel? = nil
}

extension EnvironmentValues {
    var appTrackingViewModel: AppTrackingViewModel? {
        get { self[AppTrackingViewModelKey.self] }
        set { self[AppTrackingViewModelKey.self] = newValue }
    }
}
