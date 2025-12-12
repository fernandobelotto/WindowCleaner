import Foundation
import SwiftData

// MARK: - Item Model

/// A sample SwiftData model representing an item with a timestamp.
///
/// Usage:
/// ```swift
/// let item = Item(timestamp: Date())
/// modelContext.insert(item)
/// ```
@Model
final class Item: Identifiable {
    // MARK: - Properties

    /// Unique identifier for the item
    var id: UUID

    /// The timestamp when the item was created
    var timestamp: Date

    // MARK: - Initialization

    /// Creates a new item with the specified timestamp.
    /// - Parameter timestamp: The creation date. Defaults to the current date.
    init(timestamp: Date = Date()) {
        id = UUID()
        self.timestamp = timestamp
    }
}

// MARK: - Sample Data

extension Item {
    /// Creates sample items for previews and testing.
    /// - Parameter count: The number of items to create.
    /// - Returns: An array of sample items.
    static func sampleItems(count: Int = 5) -> [Item] {
        (0 ..< count).map { index in
            Item(timestamp: Date().addingTimeInterval(Double(-index * 86400)))
        }
    }
}
