import Foundation
import SwiftData

// MARK: - App Usage Record

/// Persisted record of an app's usage for a specific day.
/// Used for tracking historical usage patterns and generating insights.
@Model
final class AppUsageRecord: Identifiable {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// The app's bundle identifier
    @Attribute(.spotlight)
    var bundleIdentifier: String

    /// The app's display name (cached for history display)
    var appName: String

    /// The date this record is for (normalized to start of day)
    var date: Date

    /// Total time the app was active (frontmost) in seconds
    var totalActiveTime: TimeInterval

    /// Peak memory usage observed during the day in bytes
    var peakMemoryUsage: UInt64

    /// Average memory usage during active periods in bytes
    var averageMemoryUsage: UInt64

    /// Number of times the app was activated (brought to front)
    var activationCount: Int

    /// Number of times the app was launched
    var launchCount: Int

    /// Total number of quit actions performed on this app
    var quitCount: Int

    /// When this record was last updated
    var lastUpdated: Date

    // MARK: - Initialization

    /// Creates a new usage record for an app on a specific date
    init(
        bundleIdentifier: String,
        appName: String,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.date = Calendar.current.startOfDay(for: date)
        self.totalActiveTime = 0
        self.peakMemoryUsage = 0
        self.averageMemoryUsage = 0
        self.activationCount = 0
        self.launchCount = 0
        self.quitCount = 0
        self.lastUpdated = Date()
    }

    // MARK: - Computed Properties

    /// Formatted total active time
    var formattedActiveTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: totalActiveTime) ?? "0s"
    }

    /// Formatted peak memory usage
    var formattedPeakMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(peakMemoryUsage), countStyle: .memory)
    }

    /// Formatted average memory usage
    var formattedAverageMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(averageMemoryUsage), countStyle: .memory)
    }

    // MARK: - Update Methods

    /// Records an activation event
    func recordActivation() {
        activationCount += 1
        lastUpdated = Date()
    }

    /// Records a launch event
    func recordLaunch() {
        launchCount += 1
        lastUpdated = Date()
    }

    /// Records a quit event
    func recordQuit() {
        quitCount += 1
        lastUpdated = Date()
    }

    /// Updates active time by adding the specified duration
    func addActiveTime(_ duration: TimeInterval) {
        totalActiveTime += duration
        lastUpdated = Date()
    }

    /// Updates memory statistics
    func updateMemory(current: UInt64) {
        if current > peakMemoryUsage {
            peakMemoryUsage = current
        }

        // Calculate running average
        if averageMemoryUsage == 0 {
            averageMemoryUsage = current
        } else {
            // Simple moving average
            averageMemoryUsage = (averageMemoryUsage + current) / 2
        }
        lastUpdated = Date()
    }
}

// MARK: - Predicates

extension AppUsageRecord {
    /// Predicate for finding records for a specific bundle identifier
    static func forBundle(_ bundleIdentifier: String) -> Predicate<AppUsageRecord> {
        #Predicate { record in
            record.bundleIdentifier == bundleIdentifier
        }
    }

    /// Predicate for finding records for today
    static func forToday() -> Predicate<AppUsageRecord> {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return #Predicate { record in
            record.date >= startOfToday
        }
    }

    /// Predicate for finding records within a date range
    static func inDateRange(from startDate: Date, to endDate: Date) -> Predicate<AppUsageRecord> {
        #Predicate { record in
            record.date >= startDate && record.date <= endDate
        }
    }

    /// Predicate for finding records older than a given date (for cleanup)
    static func olderThan(_ date: Date) -> Predicate<AppUsageRecord> {
        #Predicate { record in
            record.date < date
        }
    }
}

// MARK: - Fetch Descriptors

extension AppUsageRecord {
    /// Fetch descriptor for today's records, sorted by active time
    static var todayByActiveTime: FetchDescriptor<AppUsageRecord> {
        var descriptor = FetchDescriptor<AppUsageRecord>(
            predicate: forToday(),
            sortBy: [SortDescriptor(\.totalActiveTime, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        return descriptor
    }

    /// Fetch descriptor for all records for a specific app
    static func historyFor(bundleIdentifier: String) -> FetchDescriptor<AppUsageRecord> {
        FetchDescriptor<AppUsageRecord>(
            predicate: forBundle(bundleIdentifier),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
    }

    /// Fetch descriptor for the last N days
    static func lastDays(_ count: Int) -> FetchDescriptor<AppUsageRecord> {
        let startDate = Calendar.current.date(byAdding: .day, value: -count, to: Date()) ?? Date()
        return FetchDescriptor<AppUsageRecord>(
            predicate: inDateRange(from: startDate, to: Date()),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
    }
}

// MARK: - Sample Data

extension AppUsageRecord {
    /// Creates sample records for previews
    static func sampleRecords(count: Int = 7) -> [AppUsageRecord] {
        let apps = [
            ("com.apple.Safari", "Safari"),
            ("com.apple.mail", "Mail"),
            ("com.microsoft.VSCode", "Visual Studio Code"),
            ("com.spotify.client", "Spotify"),
            ("com.slack", "Slack"),
        ]

        var records: [AppUsageRecord] = []

        for dayOffset in 0 ..< count {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()

            for (bundleId, name) in apps {
                let record = AppUsageRecord(bundleIdentifier: bundleId, appName: name, date: date)
                record.totalActiveTime = Double.random(in: 300 ... 14400) // 5min to 4hrs
                record.peakMemoryUsage = UInt64.random(in: 100_000_000 ... 2_000_000_000) // 100MB to 2GB
                record.averageMemoryUsage = record.peakMemoryUsage / 2
                record.activationCount = Int.random(in: 1 ... 50)
                record.launchCount = Int.random(in: 1 ... 5)
                records.append(record)
            }
        }

        return records
    }
}
