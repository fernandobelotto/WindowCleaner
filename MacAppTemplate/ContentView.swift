import os
import SwiftData
import SwiftUI

// MARK: - ContentView

/// Main content view composing the NavigationSplitView with sidebar and detail areas.
///
/// Acts as the compositor, delegating to:
/// - `SidebarView` for the sidebar list
/// - `DetailView` for the detail area
/// - `ContentViewModel` for state and actions
struct ContentView: View {
    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.undoManager)
    private var undoManager

    // MARK: - Query

    @Query(sort: \Item.timestamp, order: .reverse)
    private var items: [Item]

    // MARK: - State

    @State
    private var viewModel: ContentViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                mainContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            viewModel = ContentViewModel(modelContext: modelContext)
        }
        .onChange(of: undoManager) { _, newValue in
            modelContext.undoManager = newValue
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(viewModel: ContentViewModel) -> some View {
        NavigationSplitView(columnVisibility: Binding(
            get: { viewModel.columnVisibility },
            set: { viewModel.columnVisibility = $0 }
        )) {
            SidebarView(
                items: items,
                selectedItem: Binding(
                    get: { viewModel.selectedItem },
                    set: { viewModel.selectedItem = $0 }
                ),
                viewModel: viewModel
            )
        } detail: {
            DetailView(items: items, viewModel: viewModel)
        }
        .contentViewNotifications(viewModel: viewModel, items: items)
        .onAppear { modelContext.undoManager = undoManager }
        .onChange(of: viewModel.selectedItem) { _, _ in
            viewModel.handleSelectionChange()
        }
    }
}

// MARK: - Notification Handling Modifier

private extension View {
    /// Attaches notification handlers for ContentView actions.
    func contentViewNotifications(viewModel: ContentViewModel, items: [Item]) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .createNewItem)) { _ in
            viewModel.addItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelectedItem)) { _ in
            if let item = viewModel.selectedItem { viewModel.deleteItem(item) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .duplicateSelectedItem)) { _ in
            if let item = viewModel.selectedItem { viewModel.duplicateItem(item) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            viewModel.toggleSidebar()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            viewModel.refreshContent()
        }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: .clearAllData)) { _ in
                viewModel.showClearDataAlert = true
            }
            .alert("Clear All Data", isPresented: Binding(
                get: { viewModel.showClearDataAlert },
                set: { viewModel.showClearDataAlert = $0 }
            )) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) { viewModel.clearAllData(items: items) }
            } message: {
                Text("This will permanently delete all items. This action cannot be undone.")
            }
        #endif
    }
}

// MARK: - Previews

#Preview("Empty State") {
    ContentView()
        .modelContainer(.preview)
}

#Preview("With Data") {
    ContentView()
        .modelContainer(.previewWithData)
}

#Preview("Dark Mode") {
    ContentView()
        .modelContainer(.previewWithData)
        .preferredColorScheme(.dark)
}
