import SwiftData
import SwiftUI

// MARK: - DetailView

/// Detail view for the NavigationSplitView, displaying selected item content.
///
/// Part of the ContentView composition, this view handles:
/// - NavigationStack for detail navigation
/// - Item detail display
/// - Route destination mapping
/// - Empty state when no item is selected
struct DetailView: View {
    // MARK: - Properties

    /// The list of items (for route destination lookup)
    let items: [Item]

    /// ViewModel containing navigation state
    var viewModel: ContentViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Binding(
            get: { viewModel.navigationManager.path },
            set: { viewModel.navigationManager.path = $0 }
        )) {
            detailContent
                .navigationDestination(for: NavigationRoute.self) { route in
                    routeDestination(for: route)
                }
        }
    }

    // MARK: - Detail Content

    @ViewBuilder private var detailContent: some View {
        if let item = viewModel.selectedItem {
            ItemDetailView(item: item)
                .accessibilityIdentifier("DetailView")
        } else {
            EmptyStateView(.noSelection)
        }
    }

    // MARK: - Route Destination

    /// Maps navigation routes to their destination views.
    @ViewBuilder
    private func routeDestination(for route: NavigationRoute) -> some View {
        switch route {
        case let .itemDetail(itemID):
            if let item = items.first(where: { $0.id == itemID }) {
                ItemDetailView(item: item)
            } else {
                EmptyStateView(.noSelection)
            }

        case let .itemEdit(itemID):
            if let item = items.first(where: { $0.id == itemID }) {
                ItemEditView(item: item)
            } else {
                EmptyStateView(.noSelection)
            }
        }
    }
}

// MARK: - Preview

private struct DetailPreview: View {
    @Environment(\.modelContext)
    private var modelContext

    let items: [Item]
    let selectedItem: Item?

    var body: some View {
        let viewModel = ContentViewModel(modelContext: modelContext)
        viewModel.selectedItem = selectedItem

        return DetailView(items: items, viewModel: viewModel)
            .frame(width: 500, height: 400)
    }
}

#Preview("With Selection") {
    let items = Item.sampleItems(count: 3)
    return DetailPreview(items: items, selectedItem: items.first)
        .modelContainer(.preview)
}

#Preview("No Selection") {
    DetailPreview(items: Item.sampleItems(count: 3), selectedItem: nil)
        .modelContainer(.preview)
}
