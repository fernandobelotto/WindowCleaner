import os
import SwiftUI

// MARK: - ItemDetailView

/// Displays detailed information for a selected item.
///
/// This view presents item information in a grouped form layout with two sections:
/// - **Details**: Shows creation timestamp in both absolute and relative formats
/// - **Identifier**: Displays the unique UUID for the item (selectable for copying)
///
/// ## Toolbar Actions
/// - **Edit**: Navigates to the item edit view using ``NavigationManager``
/// - **Share**: Provides a share sheet to share the item's formatted date
///
/// ## Navigation
/// The view integrates with ``NavigationManager`` to handle programmatic navigation
/// to the edit screen when the Edit button is tapped.
///
/// ## Usage
/// ```swift
/// NavigationStack {
///     ItemDetailView(item: myItem)
/// }
/// ```
///
/// - Note: This view uses `@Bindable` to allow two-way binding with the item,
///   enabling updates from the edit view to propagate back.
struct ItemDetailView: View {
    // MARK: - Properties

    /// The item to display. Uses `@Bindable` for two-way data flow.
    @Bindable var item: Item

    /// Navigation manager for programmatic navigation
    @Environment(\.navigationManager)
    private var navigationManager

    // MARK: - Body

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Created") {
                    Text(item.timestamp, format: Date.FormatStyle(date: .complete, time: .standard))
                }

                LabeledContent("Relative") {
                    Text(item.relativeDate)
                }
            }

            Section("Identifier") {
                Text(item.id.uuidString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Item Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    navigationManager.navigate(to: .itemEdit(item.id))
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .help("Edit this item")
            }

            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: item.formattedDate)
            }
        }
    }
}

// MARK: - Preview

#Preview("Item Detail") {
    NavigationStack {
        ItemDetailView(item: Item(timestamp: Date()))
    }
    .frame(width: 400, height: 300)
}

#Preview("Old Item") {
    NavigationStack {
        ItemDetailView(item: Item(timestamp: Date().addingTimeInterval(-86400 * 7)))
    }
    .frame(width: 400, height: 300)
}
