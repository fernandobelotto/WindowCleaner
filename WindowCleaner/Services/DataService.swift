import Foundation
import os
import SwiftData

// MARK: - Data Errors

/// Errors that can occur during data operations.
enum DataError: LocalizedError {
    /// Failed to create the ModelContainer
    case containerCreationFailed(Error)

    /// Schema migration failed
    case migrationFailed(Error)

    /// Failed to fetch data from SwiftData
    case fetchFailed(Error)

    /// Failed to save changes to SwiftData
    case saveFailed(Error)

    /// A required model was not found
    case modelNotFound

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .containerCreationFailed:
            "Failed to initialize data storage"
        case .migrationFailed:
            "Failed to migrate data to new format"
        case .fetchFailed:
            "Failed to load data"
        case .saveFailed:
            "Failed to save changes"
        case .modelNotFound:
            "The requested item was not found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .containerCreationFailed:
            "Try restarting the app. If the problem persists, reinstall the app."
        case .migrationFailed:
            "Your data may need to be reset. Please contact support."
        case .fetchFailed:
            "Try refreshing the data or restarting the app."
        case .saveFailed:
            "Check available storage and try again."
        case .modelNotFound:
            "The item may have been deleted."
        }
    }

    var failureReason: String? {
        switch self {
        case let .containerCreationFailed(error),
             let .migrationFailed(error),
             let .fetchFailed(error),
             let .saveFailed(error):
            error.localizedDescription
        case .modelNotFound:
            nil
        }
    }
}

// MARK: - Versioned Schema V1

/// Version 1 of the schema.
///
/// This is the initial schema version containing the base models.
/// When adding new properties or models, create a new schema version
/// and add a migration stage to `ItemMigrationPlan`.
enum ItemSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self]
    }
}

// MARK: - Versioned Schema V2

/// Version 2 of the schema - adds AppUsageRecord for tracking app usage history.
enum ItemSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, AppUsageRecord.self]
    }
}

// MARK: - Migration Plan

/// Migration plan for the schema.
///
/// This plan manages schema migrations between versions.
///
/// To add a new migration:
/// 1. Create a new schema version with the updated models
/// 2. Add the new schema to the `schemas` array
/// 3. Add a `MigrationStage` to the `stages` array
enum ItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ItemSchemaV1.self, ItemSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            // V1 -> V2: Add AppUsageRecord model (lightweight migration)
            .lightweight(fromVersion: ItemSchemaV1.self, toVersion: ItemSchemaV2.self),
        ]
    }
}

// MARK: - Data Service

/// Centralized service for managing SwiftData persistence.
///
/// This service handles:
/// - ModelContainer creation and configuration
/// - Schema versioning and migrations
/// - Preview and testing containers
///
/// Usage:
/// ```swift
/// // In App struct
/// var sharedModelContainer: ModelContainer = {
///     do {
///         return try DataService.makeContainer()
///     } catch {
///         fatalError("Could not create ModelContainer: \(error)")
///     }
/// }()
/// ```
@MainActor
enum DataService {
    // MARK: - Container Factory

    /// Creates a ModelContainer configured for production use.
    ///
    /// The container automatically uses in-memory storage during UI testing
    /// to ensure a clean state for each test run.
    ///
    /// - Returns: A configured ModelContainer
    /// - Throws: `DataError.containerCreationFailed` if creation fails
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: ItemSchemaV2.self)

        // Use in-memory storage during UI testing for clean state
        let isInMemory = Config.isUITesting

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isInMemory,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: ItemMigrationPlan.self,
                configurations: modelConfiguration
            )

            Log.data.info("ModelContainer created successfully (in-memory: \(isInMemory))")
            return container
        } catch {
            Log.data.critical("Failed to create ModelContainer: \(error.localizedDescription)")
            throw DataError.containerCreationFailed(error)
        }
    }

    /// Creates an in-memory ModelContainer for previews and testing.
    ///
    /// - Returns: An in-memory ModelContainer
    static func makePreviewContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: ItemSchemaV2.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // In previews, we can fall back to a basic container
            Log.data.error("Failed to create preview container: \(error.localizedDescription)")
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: Item.self, AppUsageRecord.self, configurations: config)
        }
    }

    /// Creates an in-memory ModelContainer pre-populated with sample data.
    ///
    /// - Parameter itemCount: Number of sample items to create (default: 10)
    /// - Returns: An in-memory ModelContainer with sample data
    static func makePreviewContainer(withSampleItems itemCount: Int) -> ModelContainer {
        let container = makePreviewContainer()
        let context = container.mainContext

        for dayOffset in 0 ..< itemCount {
            let item = Item(timestamp: Date().addingTimeInterval(Double(-dayOffset * 86400)))
            context.insert(item)
        }

        return container
    }
}

// MARK: - ModelContainer Preview Extensions

extension ModelContainer {
    /// In-memory container for previews and testing
    @MainActor
    static var preview: ModelContainer {
        DataService.makePreviewContainer()
    }

    /// Empty preview container (alias for preview)
    @MainActor
    static var previewEmpty: ModelContainer {
        DataService.makePreviewContainer()
    }

    /// Preview container with sample data (10 items)
    @MainActor
    static var previewWithData: ModelContainer {
        DataService.makePreviewContainer(withSampleItems: 10)
    }

    /// Preview container with a single recent item
    @MainActor
    static var previewWithRecentItem: ModelContainer {
        DataService.makePreviewContainer(withSampleItems: 1)
    }

    /// Preview container with many items (50 items for scroll testing)
    @MainActor
    static var previewWithManyItems: ModelContainer {
        DataService.makePreviewContainer(withSampleItems: 50)
    }
}
