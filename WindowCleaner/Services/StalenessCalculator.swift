import Foundation
import os

// MARK: - Double Extension

private extension Double {
    /// Returns self if non-zero, otherwise returns the default value
    func nonZeroOr(_ defaultValue: Double) -> Double {
        self != 0 ? self : defaultValue
    }
}

// MARK: - Staleness Calculator

/// Calculates a "staleness" score for apps based on inactivity, memory usage, and CPU usage.
/// Higher scores indicate apps that are good candidates for closing.
@MainActor
@Observable
final class StalenessCalculator {
    // MARK: - Singleton

    static let shared = StalenessCalculator()

    // MARK: - Configuration

    /// Weight for inactivity time in the score (0-1)
    var inactivityWeight: Double {
        UserDefaults.standard.double(forKey: UserDefaultsKey.stalenessInactivityWeight).nonZeroOr(0.50)
    }

    /// Weight for memory usage in the score (0-1)
    var memoryWeight: Double {
        UserDefaults.standard.double(forKey: UserDefaultsKey.stalenessMemoryWeight).nonZeroOr(0.40)
    }

    /// Weight for CPU usage in the score (0-1)
    var cpuWeight: Double {
        UserDefaults.standard.double(forKey: UserDefaultsKey.stalenessCPUWeight).nonZeroOr(0.10)
    }

    /// Threshold above which an app is considered "stale" (0-1)
    var staleThreshold: Double {
        UserDefaults.standard.double(forKey: UserDefaultsKey.stalenessThreshold).nonZeroOr(0.60)
    }

    /// Maximum inactivity time to normalize against (in minutes)
    var maxInactivityMinutes: Double {
        UserDefaults.standard.double(forKey: UserDefaultsKey.maxInactivityMinutes).nonZeroOr(60.0)
    }

    /// Maximum memory to normalize against (in GB)
    var maxMemoryGB: Double = 4.0

    // MARK: - Initialization

    private init() {
        Log.tracking.info("StalenessCalculator initialized")
    }

    // MARK: - Score Calculation

    /// Calculates the staleness score for an app
    /// - Parameter app: The tracked app to score
    /// - Returns: A score from 0 (active/essential) to 1 (very stale/wasteful)
    func calculateScore(for app: TrackedApp) -> Double {
        // Don't score protected or system apps
        guard !app.isProtected, !app.isSystemApp else {
            return 0
        }

        // Don't score currently active app
        guard !app.isActive else {
            return 0
        }

        let inactivityScore = calculateInactivityScore(for: app)
        let memoryScore = calculateMemoryScore(for: app)
        let cpuScore = calculateCPUScore(for: app)

        let totalScore = (inactivityWeight * inactivityScore)
            + (memoryWeight * memoryScore)
            + (cpuWeight * cpuScore)

        return min(max(totalScore, 0), 1)
    }

    /// Calculates scores for all apps and returns them sorted by staleness
    /// - Parameter apps: The apps to score
    /// - Returns: Apps sorted by staleness score (highest first)
    func rankApps(_ apps: [TrackedApp]) -> [(app: TrackedApp, score: Double)] {
        apps.map { app in
            (app: app, score: calculateScore(for: app))
        }
        .sorted { $0.score > $1.score }
    }

    /// Returns apps that are considered stale (above threshold)
    /// - Parameter apps: The apps to filter
    /// - Returns: Stale apps sorted by score
    func staleApps(from apps: [TrackedApp]) -> [TrackedApp] {
        rankApps(apps)
            .filter { $0.score >= staleThreshold }
            .map(\.app)
    }

    /// Returns the total memory that could be reclaimed by closing stale apps
    /// - Parameter apps: The apps to analyze
    /// - Returns: Potential memory savings in bytes
    func potentialMemorySavings(from apps: [TrackedApp]) -> UInt64 {
        staleApps(from: apps).reduce(0) { $0 + $1.memoryUsage }
    }

    /// Formatted potential memory savings
    func formattedPotentialSavings(from apps: [TrackedApp]) -> String {
        let bytes = potentialMemorySavings(from: apps)
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    // MARK: - Individual Score Components

    /// Calculates the inactivity score (0-1)
    /// Higher score = longer since active
    private func calculateInactivityScore(for app: TrackedApp) -> Double {
        let minutesInactive = app.timeSinceActive / 60.0
        let normalized = minutesInactive / maxInactivityMinutes
        return min(normalized, 1.0)
    }

    /// Calculates the memory score (0-1)
    /// Higher score = using more memory
    private func calculateMemoryScore(for app: TrackedApp) -> Double {
        let memoryGB = Double(app.memoryUsage) / 1_073_741_824.0 // Convert to GB
        let normalized = memoryGB / maxMemoryGB
        return min(normalized, 1.0)
    }

    /// Calculates the CPU score (0-1)
    /// Higher score = LOWER CPU usage (idle apps score higher)
    private func calculateCPUScore(for app: TrackedApp) -> Double {
        // Invert: low CPU = high staleness
        // An app using 0% CPU is more "stale" than one using 50%
        let cpuUsage = min(app.cpuUsage, 100.0)
        return 1.0 - (cpuUsage / 100.0)
    }

    // MARK: - Score Interpretation

    /// Returns a human-readable description of the staleness level
    func stalenessLevel(for score: Double) -> StalenessLevel {
        switch score {
        case 0 ..< 0.2: .active
        case 0.2 ..< 0.4: .recent
        case 0.4 ..< 0.6: .idle
        case 0.6 ..< 0.8: .stale
        default: .veryStale
        }
    }
}

// MARK: - Staleness Level

/// Human-readable staleness levels
enum StalenessLevel: String, CaseIterable, Identifiable {
    case active = "Active"
    case recent = "Recently Used"
    case idle = "Idle"
    case stale = "Stale"
    case veryStale = "Very Stale"

    var id: String { rawValue }

    /// Color representation for UI
    var colorName: String {
        switch self {
        case .active: "green"
        case .recent: "blue"
        case .idle: "yellow"
        case .stale: "orange"
        case .veryStale: "red"
        }
    }

    /// SF Symbol for this level
    var systemImage: String {
        switch self {
        case .active: "circle.fill"
        case .recent: "circle.lefthalf.filled"
        case .idle: "circle.dotted"
        case .stale: "exclamationmark.circle"
        case .veryStale: "exclamationmark.circle.fill"
        }
    }

    /// Short description for tooltips
    var description: String {
        switch self {
        case .active: "Currently in use"
        case .recent: "Used within the last few minutes"
        case .idle: "Not used for a while"
        case .stale: "Good candidate for closing"
        case .veryStale: "Recommended to close"
        }
    }
}

// MARK: - TrackedApp Extension

extension TrackedApp {
    /// Calculates and returns the staleness score for this app
    var stalenessScore: Double {
        StalenessCalculator.shared.calculateScore(for: self)
    }

    /// Returns the staleness level for this app
    var stalenessLevel: StalenessLevel {
        StalenessCalculator.shared.stalenessLevel(for: stalenessScore)
    }

    /// Whether this app is considered stale
    var isStale: Bool {
        stalenessScore >= StalenessCalculator.shared.staleThreshold
    }
}

// MARK: - UserDefaults Keys

extension UserDefaultsKey {
    static let stalenessInactivityWeight = "stalenessInactivityWeight"
    static let stalenessMemoryWeight = "stalenessMemoryWeight"
    static let stalenessCPUWeight = "stalenessCPUWeight"
    static let stalenessThreshold = "stalenessThreshold"
    static let pollingInterval = "pollingInterval"
}
