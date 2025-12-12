import os
import SwiftUI

// MARK: - ItemEditView

/// Provides an editing interface for modifying an item's properties.
///
/// This view displays a form allowing users to edit item properties:
/// - **Timestamp**: Adjustable via a `DatePicker` component
/// - **Identifier**: Read-only display of the item's unique UUID
///
/// ## Editing Flow
/// 1. User modifies the timestamp using the date picker
/// 2. Changes are stored in local `@State` until saved
/// 3. Tapping "Save" commits changes to the item and navigates back
/// 4. Tapping "Cancel" discards changes and navigates back
///
/// ## Data Binding
/// The view uses `@Bindable` for the item, allowing SwiftData to automatically
/// persist changes when the Save button updates the item's properties.
///
/// ## Usage
/// ```swift
/// NavigationStack {
///     ItemEditView(item: myItem)
/// }
/// ```
///
/// - Note: The view maintains a local copy of the timestamp in `@State` to
///   support cancellation without modifying the original item.
struct ItemEditView: View {
    // MARK: - Properties

    /// The item being edited. Changes are committed on Save.
    @Bindable var item: Item

    /// Navigation manager for programmatic navigation
    @Environment(\.navigationManager)
    private var navigationManager

    // MARK: - State

    /// Local copy of the timestamp being edited. Changes are only applied to the item when saved.
    @State
    private var editedTimestamp: Date

    // MARK: - Initialization

    /// Creates an edit view for the specified item.
    /// - Parameter item: The item to edit
    init(item: Item) {
        self.item = item
        _editedTimestamp = State(initialValue: item.timestamp)
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section("Edit Details") {
                DatePicker("Timestamp", selection: $editedTimestamp)
            }

            Section("Identifier") {
                Text(item.id.uuidString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Item")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    navigationManager.pop()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    item.timestamp = editedTimestamp
                    Log.data.info("Item updated")
                    navigationManager.pop()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Edit Item") {
    NavigationStack {
        ItemEditView(item: Item(timestamp: Date()))
    }
    .frame(width: 400, height: 300)
}
