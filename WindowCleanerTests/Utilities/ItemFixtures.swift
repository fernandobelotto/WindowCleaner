import Foundation
@testable import WindowCleaner

// MARK: - Item Fixtures

/// Reusable test fixtures for `Item` model testing.
///
/// Usage:
/// ```swift
/// let item = ItemFixtures.recentItem
/// let items = ItemFixtures.makeItems(count: 10)
/// ```
enum ItemFixtures {
    // MARK: - Fixed Dates

    /// A fixed reference date for consistent testing (2024-01-15 12:00:00 UTC)
    static let referenceDate = Date(timeIntervalSince1970: 1705320000)

    /// One hour before reference date
    static let oneHourAgo = referenceDate.addingTimeInterval(-3600)

    /// One day before reference date
    static let oneDayAgo = referenceDate.addingTimeInterval(-86400)

    /// One week before reference date
    static let oneWeekAgo = referenceDate.addingTimeInterval(-604800)

    // MARK: - Sample Items

    /// Creates an item with the reference date timestamp.
    static var referenceItem: Item {
        Item(timestamp: referenceDate)
    }

    /// Creates an item with the current timestamp.
    static var recentItem: Item {
        Item(timestamp: Date())
    }

    /// Creates an item from one hour ago.
    static var hourOldItem: Item {
        Item(timestamp: oneHourAgo)
    }

    /// Creates an item from one day ago.
    static var dayOldItem: Item {
        Item(timestamp: oneDayAgo)
    }

    /// Creates an item from one week ago.
    static var weekOldItem: Item {
        Item(timestamp: oneWeekAgo)
    }

    // MARK: - Factory Methods

    /// Creates multiple items with sequential timestamps.
    /// - Parameters:
    ///   - count: The number of items to create.
    ///   - startDate: The starting date. Defaults to the reference date.
    ///   - interval: The time interval between items in seconds. Defaults to one day (86400).
    /// - Returns: An array of items with decreasing timestamps.
    static func makeItems(
        count: Int,
        startDate: Date = referenceDate,
        interval: TimeInterval = 86400
    ) -> [Item] {
        (0 ..< count).map { index in
            Item(timestamp: startDate.addingTimeInterval(Double(-index) * interval))
        }
    }

    /// Creates items spanning a specific time range.
    /// - Parameters:
    ///   - count: The number of items to create.
    ///   - from: The most recent date.
    ///   - to: The oldest date.
    /// - Returns: An array of items distributed across the time range.
    static func makeItems(count: Int, from: Date, to: Date) -> [Item] {
        guard count > 1 else {
            return [Item(timestamp: from)]
        }

        let totalInterval = from.timeIntervalSince(to)
        let step = totalInterval / Double(count - 1)

        return (0 ..< count).map { index in
            Item(timestamp: from.addingTimeInterval(-Double(index) * step))
        }
    }
}
