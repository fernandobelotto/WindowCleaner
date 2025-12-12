import SwiftUI

// MARK: - ItemRow

/// A reusable list row component for displaying item information.
///
/// `ItemRow` presents a compact view of an item suitable for display in a sidebar
/// or list context. It shows both absolute and relative timestamps with a
/// document icon.
///
/// ## Layout
/// The row uses an HStack layout with:
/// - Leading icon (SF Symbol "doc.text")
/// - VStack containing formatted date and relative time
/// - Trailing spacer for alignment
///
/// ## Formatting
/// - **Primary text**: Abbreviated date and shortened time (e.g., "Jan 15, 2024 at 3:30 PM")
/// - **Secondary text**: Relative time description (e.g., "2 hours ago", "Yesterday")
///
/// ## Usage
/// ```swift
/// List {
///     ForEach(items) { item in
///         ItemRow(item: item)
///     }
/// }
/// ```
///
/// - Note: Uses `Metrics` constants for consistent spacing across the app
/// - SeeAlso: ``Item`` for the data model being displayed
struct ItemRow: View {
    // MARK: - Properties

    /// The item to display in this row.
    let item: Item

    // MARK: - Body

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: Metrics.iconSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.formattedDate)
                    .font(.body)
                    .lineLimit(1)

                Text(item.relativeDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, Metrics.spacingXS)
        .contentShape(Rectangle())
    }
}

// MARK: - Item Extensions

extension Item {
    /// Returns the item's timestamp formatted for display.
    ///
    /// Uses abbreviated date format with shortened time.
    ///
    /// ## Example Output
    /// - "Jan 15, 2024 at 3:30 PM"
    /// - "Dec 6, 2025 at 10:15 AM"
    var formattedDate: String {
        timestamp.formatted(date: .abbreviated, time: .shortened)
    }

    /// Returns a human-readable relative time description.
    ///
    /// Uses named presentation style for clarity.
    ///
    /// ## Example Output
    /// - "2 minutes ago"
    /// - "1 hour ago"
    /// - "Yesterday"
    /// - "Last week"
    var relativeDate: String {
        timestamp.formatted(.relative(presentation: .named))
    }
}

// MARK: - Preview

#Preview("Item Row") {
    List {
        ItemRow(item: Item(timestamp: Date()))
        ItemRow(item: Item(timestamp: Date().addingTimeInterval(-3600)))
        ItemRow(item: Item(timestamp: Date().addingTimeInterval(-86400)))
        ItemRow(item: Item(timestamp: Date().addingTimeInterval(-604800)))
    }
    .frame(width: 300)
}
