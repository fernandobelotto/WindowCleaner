import SwiftData
import SwiftUI

// MARK: - Preview Helpers

/// Utilities for creating rich preview data and configurations.
///
/// Usage:
/// ```swift
/// #Preview("Custom Items") {
///     ContentView()
///         .modelContainer(PreviewData.container(with: .varied))
/// }
/// ```
enum PreviewData {
    // MARK: - Container Scenarios

    /// Predefined scenarios for preview containers.
    enum Scenario {
        /// Empty container with no data
        case empty

        /// Standard set of 10 items
        case standard

        /// Single item created just now
        case singleRecent

        /// Large dataset for scroll testing (50 items)
        case large

        /// Items with varied timestamps for testing relative dates
        case varied

        /// Items spanning exactly one week
        case oneWeek
    }

    /// Creates a preview container for the specified scenario.
    /// - Parameter scenario: The data scenario to use.
    /// - Returns: A configured `ModelContainer` with appropriate sample data.
    @MainActor
    static func container(with scenario: Scenario) -> ModelContainer {
        switch scenario {
        case .empty:
            .previewEmpty

        case .standard:
            .previewWithData

        case .singleRecent:
            .previewWithRecentItem

        case .large:
            .previewWithManyItems

        case .varied:
            makeVariedContainer()

        case .oneWeek:
            makeOneWeekContainer()
        }
    }

    // MARK: - Custom Container Builders

    /// Creates a container with items at varied time intervals.
    @MainActor
    private static func makeVariedContainer() -> ModelContainer {
        let container = ModelContainer.preview
        let context = container.mainContext

        let intervals: [TimeInterval] = [
            0, // Just now
            -60, // 1 minute ago
            -3600, // 1 hour ago
            -7200, // 2 hours ago
            -86400, // 1 day ago
            -172800, // 2 days ago
            -604800, // 1 week ago
            -2592000, // 30 days ago
        ]

        for interval in intervals {
            let item = Item(timestamp: Date().addingTimeInterval(interval))
            context.insert(item)
        }

        return container
    }

    /// Creates a container with items spanning exactly one week.
    @MainActor
    private static func makeOneWeekContainer() -> ModelContainer {
        let container = ModelContainer.preview
        let context = container.mainContext

        // One item per day for the past week
        for day in 0 ..< 7 {
            let item = Item(timestamp: Date().addingTimeInterval(Double(-day * 86400)))
            context.insert(item)
        }

        return container
    }
}

// MARK: - Sample Items

extension PreviewData {
    /// Creates sample items without inserting into a context.
    /// Useful for previewing individual views that take items as parameters.
    enum SampleItems {
        /// An item created just now
        static var recent: Item {
            Item(timestamp: Date())
        }

        /// An item from 1 hour ago
        static var hourOld: Item {
            Item(timestamp: Date().addingTimeInterval(-3600))
        }

        /// An item from 1 day ago
        static var dayOld: Item {
            Item(timestamp: Date().addingTimeInterval(-86400))
        }

        /// An item from 1 week ago
        static var weekOld: Item {
            Item(timestamp: Date().addingTimeInterval(-604800))
        }

        /// An item from 1 month ago
        static var monthOld: Item {
            Item(timestamp: Date().addingTimeInterval(-2592000))
        }

        /// Creates an array of items with the specified count.
        /// - Parameter count: Number of items to create.
        /// - Returns: Array of items with decreasing timestamps (1 day apart).
        static func items(count: Int) -> [Item] {
            (0 ..< count).map { index in
                Item(timestamp: Date().addingTimeInterval(Double(-index * 86400)))
            }
        }
    }
}

// MARK: - Preview View Modifiers

extension View {
    /// Applies common preview styling for macOS window simulation.
    /// - Parameters:
    ///   - width: Window width. Defaults to 800.
    ///   - height: Window height. Defaults to 600.
    /// - Returns: A view with the specified frame and padding.
    func previewWindow(width: CGFloat = 800, height: CGFloat = 600) -> some View {
        frame(width: width, height: height)
            .background(Color.appBackground)
    }

    /// Applies preview styling for a sidebar component.
    /// - Parameter width: Sidebar width. Defaults to 250.
    /// - Returns: A view with sidebar-appropriate styling.
    func previewSidebar(width: CGFloat = 250) -> some View {
        frame(width: width)
            .background(Color.appBackground)
    }

    /// Applies preview styling for a detail view component.
    /// - Parameters:
    ///   - width: Detail view width. Defaults to 400.
    ///   - height: Detail view height. Defaults to 300.
    /// - Returns: A view with detail-appropriate styling.
    func previewDetail(width: CGFloat = 400, height: CGFloat = 300) -> some View {
        frame(width: width, height: height)
            .background(Color.appBackground)
    }
}

// MARK: - Preview Environment Helpers

extension View {
    /// Configures the view with a preview model container for the given scenario.
    /// - Parameter scenario: The preview data scenario to use.
    /// - Returns: A view configured with the appropriate model container.
    @MainActor
    func previewModelContainer(_ scenario: PreviewData.Scenario) -> some View {
        modelContainer(PreviewData.container(with: scenario))
    }
}
