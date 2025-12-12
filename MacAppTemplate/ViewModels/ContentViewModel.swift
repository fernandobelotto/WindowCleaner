import os
import SwiftData
import SwiftUI

// MARK: - ContentViewModel

/// ViewModel for managing ContentView state and actions.
///
/// Handles item CRUD operations, sidebar visibility, and navigation state.
/// Uses @Observable for automatic SwiftUI integration.
///
/// Usage:
/// ```swift
/// @State private var viewModel: ContentViewModel?
///
/// var body: some View {
///     ContentView()
///         .task {
///             viewModel = ContentViewModel(modelContext: modelContext)
///         }
/// }
/// ```
@Observable
final class ContentViewModel {
    // MARK: - State

    /// Currently selected item in the sidebar
    var selectedItem: Item?

    /// Navigation split view column visibility
    var columnVisibility: NavigationSplitViewVisibility = .all

    /// Navigation manager for programmatic navigation in the detail area
    var navigationManager = NavigationManager.shared

    /// Controls the clear all data confirmation alert (DEBUG only)
    #if DEBUG
        var showClearDataAlert = false
    #endif

    // MARK: - Dependencies

    /// SwiftData model context for persistence operations
    private let modelContext: ModelContext

    // MARK: - Initialization

    /// Creates a new ContentViewModel.
    /// - Parameter modelContext: The SwiftData model context for persistence operations.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Item Actions

    /// Creates a new item and selects it.
    func addItem() {
        withAnimation(.spring(duration: Metrics.animationDuration)) {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
            selectedItem = newItem
            Log.data.info("Created new item")
        }
    }

    /// Deletes items at the specified offsets.
    /// - Parameters:
    ///   - items: The current list of items (from @Query).
    ///   - offsets: The index set of items to delete.
    func deleteItems(items: [Item], at offsets: IndexSet) {
        withAnimation(.spring(duration: Metrics.animationDuration)) {
            for index in offsets {
                let item = items[index]
                if selectedItem == item {
                    selectedItem = nil
                }
                modelContext.delete(item)
            }
            Log.data.info("Deleted \(offsets.count) item(s)")
            NotificationManager.shared.notifyItemDeleted()
        }
    }

    /// Deletes a specific item.
    /// - Parameter item: The item to delete.
    func deleteItem(_ item: Item) {
        withAnimation(.spring(duration: Metrics.animationDuration)) {
            if selectedItem == item {
                selectedItem = nil
            }
            modelContext.delete(item)
            Log.data.info("Deleted item")
            NotificationManager.shared.notifyItemDeleted()
        }
    }

    /// Duplicates a specific item and selects the copy.
    /// - Parameter item: The item to duplicate.
    func duplicateItem(_ item: Item) {
        withAnimation(.spring(duration: Metrics.animationDuration)) {
            let newItem = Item(timestamp: item.timestamp)
            modelContext.insert(newItem)
            selectedItem = newItem
            Log.data.info("Duplicated item")
            NotificationManager.shared.notifyItemDuplicated()
        }
    }

    // MARK: - UI Actions

    /// Toggles the sidebar visibility.
    func toggleSidebar() {
        withAnimation(.spring(duration: Metrics.animationDuration)) {
            switch columnVisibility {
            case .all:
                columnVisibility = .detailOnly
            case .detailOnly:
                columnVisibility = .all
            default:
                columnVisibility = .all
            }
            Log.ui.debug("Toggled sidebar visibility")
        }
    }

    /// Refreshes the current content.
    func refreshContent() {
        // Example refresh action - in a real app, this might reload data from a server
        Log.ui.info("Content refreshed")
    }

    // MARK: - Navigation Actions

    /// Resets the navigation stack when item selection changes.
    func handleSelectionChange() {
        navigationManager.popToRoot()
    }

    // MARK: - Debug Actions

    #if DEBUG
        /// Clears all data from the model context.
        /// - Parameter items: The current list of items (from @Query).
        func clearAllData(items: [Item]) {
            withAnimation(.spring(duration: Metrics.animationDuration)) {
                selectedItem = nil
                for item in items {
                    modelContext.delete(item)
                }
                Log.data.info("Debug: Cleared all data (\(items.count) items)")
                NotificationManager.shared.notifyCustom(
                    title: "Data Cleared",
                    message: "All items have been deleted."
                )
            }
        }
    #endif
}
