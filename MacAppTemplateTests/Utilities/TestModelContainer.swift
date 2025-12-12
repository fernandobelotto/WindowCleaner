import Foundation
@testable import MacAppTemplate
import SwiftData

// MARK: - Test Model Container

/// Utilities for creating in-memory model containers for testing.
///
/// Usage:
/// ```swift
/// let container = try TestModelContainer.makeInMemory()
/// let context = container.mainContext
/// ```
enum TestModelContainer {
    /// Creates an in-memory model container for isolated testing.
    /// - Returns: A new in-memory `ModelContainer` configured with the app's schema.
    /// - Throws: An error if the container cannot be created.
    @MainActor
    static func makeInMemory() throws -> ModelContainer {
        let schema = Schema([Item.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Creates an in-memory model container with sample data.
    /// - Parameter itemCount: The number of sample items to create. Defaults to 5.
    /// - Returns: A new in-memory `ModelContainer` with sample items.
    /// - Throws: An error if the container cannot be created.
    @MainActor
    static func makeWithSampleData(itemCount: Int = 5) throws -> ModelContainer {
        let container = try makeInMemory()
        let context = container.mainContext

        for dayOffset in 0 ..< itemCount {
            let item = Item(timestamp: Date().addingTimeInterval(Double(-dayOffset * 86400)))
            context.insert(item)
        }

        try context.save()
        return container
    }
}

// MARK: - ModelContext Test Extensions

extension ModelContext {
    /// Fetches all items from the context.
    /// - Returns: An array of all `Item` instances.
    /// - Throws: An error if the fetch fails.
    func fetchAllItems() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>()
        return try fetch(descriptor)
    }

    /// Fetches items sorted by timestamp.
    /// - Parameter ascending: Whether to sort in ascending order. Defaults to false (newest first).
    /// - Returns: An array of sorted `Item` instances.
    /// - Throws: An error if the fetch fails.
    func fetchItemsSorted(ascending: Bool = false) throws -> [Item] {
        var descriptor = FetchDescriptor<Item>()
        descriptor.sortBy = [SortDescriptor(\Item.timestamp, order: ascending ? .forward : .reverse)]
        return try fetch(descriptor)
    }
}
