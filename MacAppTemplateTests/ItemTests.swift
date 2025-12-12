import Foundation
@testable import MacAppTemplate
import SwiftData
import Testing

// MARK: - Item Tests

/// Tests for the `Item` SwiftData model.
struct ItemTests {
    // MARK: - Initialization Tests

    @Test("Item initializes with default timestamp", .tags(.model))
    func itemInitializesWithDefaultTimestamp() {
        let beforeCreation = Date()
        let item = Item()
        let afterCreation = Date()

        #expect(item.timestamp >= beforeCreation)
        #expect(item.timestamp <= afterCreation)
    }

    @Test("Item initializes with custom timestamp", .tags(.model))
    func itemInitializesWithCustomTimestamp() {
        let customDate = ItemFixtures.referenceDate
        let item = Item(timestamp: customDate)

        #expect(item.timestamp == customDate)
    }

    @Test("Item generates unique UUID on creation", .tags(.model))
    func itemGeneratesUniqueUUID() {
        let item1 = Item()
        let item2 = Item()

        #expect(item1.id != item2.id)
    }

    @Test("Multiple items have unique IDs", .tags(.model))
    func multipleItemsHaveUniqueIDs() {
        let items = (0 ..< 100).map { _ in Item() }
        let uniqueIDs = Set(items.map(\.id))

        #expect(uniqueIDs.count == items.count)
    }

    // MARK: - Sample Items Tests

    @Test("sampleItems creates correct count", .tags(.model))
    func sampleItemsCreatesCorrectCount() {
        let items = Item.sampleItems(count: 10)

        #expect(items.count == 10)
    }

    @Test("sampleItems default count is 5", .tags(.model))
    func sampleItemsDefaultCountIs5() {
        let items = Item.sampleItems()

        #expect(items.count == 5)
    }

    @Test("sampleItems have unique IDs", .tags(.model))
    func sampleItemsHaveUniqueIDs() {
        let items = Item.sampleItems(count: 20)
        let uniqueIDs = Set(items.map(\.id))

        #expect(uniqueIDs.count == items.count)
    }

    @Test("sampleItems have descending timestamps", .tags(.model))
    func sampleItemsHaveDescendingTimestamps() {
        let items = Item.sampleItems(count: 5)

        for index in 0 ..< (items.count - 1) {
            #expect(items[index].timestamp > items[index + 1].timestamp)
        }
    }

    // MARK: - Computed Properties Tests

    @Test("formattedDate returns non-empty string", .tags(.model))
    func formattedDateReturnsNonEmptyString() {
        let item = Item(timestamp: ItemFixtures.referenceDate)

        #expect(!item.formattedDate.isEmpty)
    }

    @Test("relativeDate returns non-empty string", .tags(.model))
    func relativeDateReturnsNonEmptyString() {
        let item = Item(timestamp: Date())

        #expect(!item.relativeDate.isEmpty)
    }

    @Test("formattedDate includes date components", .tags(.model))
    func formattedDateIncludesDateComponents() {
        let item = Item(timestamp: ItemFixtures.referenceDate)
        let formatted = item.formattedDate

        // Should contain some recognizable date format
        #expect(formatted.contains(":") || formatted.contains("/") || formatted.contains(","))
    }

    // MARK: - SwiftData Persistence Tests

    @Test("Item persists to context", .tags(.model, .integration))
    @MainActor
    func itemPersistsToContext() throws {
        let container = try TestModelContainer.makeInMemory()
        let context = container.mainContext

        let item = Item(timestamp: ItemFixtures.referenceDate)
        context.insert(item)
        try context.save()

        let fetchedItems = try context.fetchAllItems()

        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.timestamp == ItemFixtures.referenceDate)
    }

    @Test("Item deletion works", .tags(.model, .integration))
    @MainActor
    func itemDeletionWorks() throws {
        let container = try TestModelContainer.makeInMemory()
        let context = container.mainContext

        let item = Item()
        context.insert(item)
        try context.save()

        context.delete(item)
        try context.save()

        let fetchedItems = try context.fetchAllItems()

        #expect(fetchedItems.isEmpty)
    }

    @Test("Multiple items persist correctly", .tags(.model, .integration))
    @MainActor
    func multipleItemsPersistCorrectly() throws {
        let container = try TestModelContainer.makeInMemory()
        let context = container.mainContext

        let items = ItemFixtures.makeItems(count: 5)
        for item in items {
            context.insert(item)
        }
        try context.save()

        let fetchedItems = try context.fetchAllItems()

        #expect(fetchedItems.count == 5)
    }

    @Test("Items can be fetched sorted by timestamp", .tags(.model, .integration))
    @MainActor
    func itemsCanBeFetchedSorted() throws {
        let container = try TestModelContainer.makeInMemory()
        let context = container.mainContext

        // Insert items in random order
        let dates = [
            ItemFixtures.oneWeekAgo,
            ItemFixtures.referenceDate,
            ItemFixtures.oneDayAgo,
        ]

        for date in dates {
            context.insert(Item(timestamp: date))
        }
        try context.save()

        let sortedItems = try context.fetchItemsSorted(ascending: false)

        #expect(sortedItems.count == 3)
        #expect(sortedItems[0].timestamp == ItemFixtures.referenceDate)
        #expect(sortedItems[1].timestamp == ItemFixtures.oneDayAgo)
        #expect(sortedItems[2].timestamp == ItemFixtures.oneWeekAgo)
    }
}
