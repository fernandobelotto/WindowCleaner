import SwiftData
import SwiftUI

// MARK: - SidebarView

/// Sidebar view displaying the list of items with selection and actions.
///
/// Part of the ContentView composition, this view handles:
/// - Item list display with selection
/// - Empty state when no items exist
/// - Add item toolbar button
/// - Delete via swipe or keyboard
struct SidebarView: View {
    // MARK: - Properties

    /// The list of items to display (from @Query in parent)
    let items: [Item]

    /// Binding to the currently selected item
    @Binding
    var selectedItem: Item?

    /// ViewModel for handling actions
    var viewModel: ContentViewModel

    // MARK: - Body

    var body: some View {
        List(selection: $selectedItem) {
            ForEach(items) { item in
                ItemRow(item: item)
                    .tag(item)
            }
            .onDelete { offsets in
                viewModel.deleteItems(items: items, at: offsets)
            }
        }
        .navigationSplitViewColumnWidth(
            min: Metrics.sidebarMinWidth,
            ideal: Metrics.sidebarIdealWidth,
            max: Metrics.sidebarMaxWidth
        )
        .toolbar {
            ToolbarItem {
                Button(action: viewModel.addItem) {
                    Label("Add Item", systemImage: "plus")
                }
                .help("Add a new item (⌘N)")
                .accessibilityIdentifier("AddItemButton")
            }
        }
        .accessibilityIdentifier("SidebarList")
        .overlay {
            if items.isEmpty {
                EmptyStateView(.noItems) {
                    viewModel.addItem()
                }
            }
        }
    }
}

// MARK: - Preview

private struct SidebarPreview: View {
    @Environment(\.modelContext)
    private var modelContext

    let items: [Item]

    var body: some View {
        NavigationSplitView {
            SidebarView(
                items: items,
                selectedItem: .constant(nil),
                viewModel: ContentViewModel(modelContext: modelContext)
            )
        } detail: {
            Text("Select an item")
        }
        .frame(width: 600, height: 400)
    }
}

#Preview("With Items") {
    SidebarPreview(items: Item.sampleItems(count: 5))
        .modelContainer(.preview)
}

#Preview("Empty State") {
    SidebarPreview(items: [])
        .modelContainer(.preview)
}
