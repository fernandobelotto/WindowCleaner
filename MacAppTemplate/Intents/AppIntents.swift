import AppIntents
import os
import SwiftData

// MARK: - Create Item Intent

/// App Intent for creating a new item via Shortcuts.
///
/// Users can trigger this from the Shortcuts app or via Siri:
/// - "Create item in MacAppTemplate"
/// - "New item in MacAppTemplate"
struct CreateItemIntent: AppIntent {
    // MARK: - Metadata

    static var title: LocalizedStringResource = "Create New Item"

    static var description = IntentDescription("Creates a new item with the current timestamp")

    static var openAppWhenRun: Bool = true

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let container = try ModelContainer(for: Item.self)
        let context = container.mainContext

        let newItem = Item(timestamp: Date())
        context.insert(newItem)
        try context.save()

        Log.data.info("Created item via App Intent")

        return .result(value: "Created item at \(newItem.formattedDate)")
    }
}

// MARK: - App Shortcuts Provider

/// Provides app shortcuts for the Shortcuts app.
///
/// These shortcuts appear in the Shortcuts app under this app's category,
/// allowing users to quickly create items via Siri or automation.
struct MacAppTemplateShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateItemIntent(),
            phrases: [
                "Create item in \(.applicationName)",
                "New item in \(.applicationName)",
                "Add item to \(.applicationName)",
            ],
            shortTitle: "New Item",
            systemImageName: "plus.circle"
        )
    }
}
