import SwiftUI

// MARK: - Empty State View

/// A reusable component for displaying empty states and error conditions.
///
/// `EmptyStateView` provides a consistent way to handle various empty or error states
/// throughout the application using SwiftUI's `ContentUnavailableView`.
///
/// ## Features
/// - Preset configurations for common scenarios (no items, no selection, errors)
/// - Custom configurations for unique use cases
/// - Optional call-to-action button
/// - Accessibility support with customizable identifiers
///
/// ## Common Presets
/// - ``Preset/noItems``: Displayed when a list has no items
/// - ``Preset/noSelection``: Shown in detail views when nothing is selected
/// - ``Preset/noSearchResults(_:)``: Displayed when search returns no results
/// - ``Preset/error(_:)``: Shows error information with recovery suggestions
///
/// ## Usage Examples
/// ```swift
/// // Simple empty state with action
/// EmptyStateView(.noItems) {
///     addItem()
/// }
///
/// // Empty state without action
/// EmptyStateView(.noSelection)
///
/// // Error state with retry action
/// EmptyStateView(.error(AppError.fetchFailed(someError))) {
///     retry()
/// }
///
/// // Custom configuration
/// EmptyStateView(configuration: .custom(myConfig)) {
///     performAction()
/// }
/// ```
///
/// - SeeAlso: ``Configuration`` for creating custom empty state configurations
/// - SeeAlso: ``Preset`` for available preset configurations
struct EmptyStateView: View {
    // MARK: - Properties

    /// The configuration determining the content and appearance of this empty state.
    let configuration: Configuration

    /// Optional closure executed when the action button is tapped.
    /// If `nil`, no button is displayed.
    var action: (() -> Void)?

    // MARK: - Initialization

    /// Creates an empty state view with a preset configuration.
    /// - Parameters:
    ///   - preset: The preset configuration to use.
    ///   - action: Optional action for the button.
    init(_ preset: Preset, action: (() -> Void)? = nil) {
        configuration = preset.configuration
        self.action = action
    }

    /// Creates an empty state view with a custom configuration.
    /// - Parameters:
    ///   - configuration: The configuration to use.
    ///   - action: Optional action for the button.
    init(configuration: Configuration, action: (() -> Void)? = nil) {
        self.configuration = configuration
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        ContentUnavailableView {
            Label(configuration.title, systemImage: configuration.systemImage)
        } description: {
            Text(configuration.description)
        } actions: {
            if let buttonTitle = configuration.buttonTitle, action != nil {
                Button(buttonTitle) {
                    action?()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .accessibilityIdentifier(configuration.accessibilityID)
    }
}

// MARK: - Configuration

extension EmptyStateView {
    /// Configuration defining the content and behavior of an empty state view.
    ///
    /// Use this to create custom empty state configurations when the provided
    /// presets don't match your specific needs.
    ///
    /// ## Example
    /// ```swift
    /// let config = EmptyStateView.Configuration(
    ///     title: "No Projects",
    ///     systemImage: "folder",
    ///     description: "Create a project to get started.",
    ///     buttonTitle: "New Project",
    ///     accessibilityID: "EmptyStateNoProjects"
    /// )
    /// ```
    struct Configuration {
        /// The main title text displayed prominently
        let title: String

        /// SF Symbol name for the icon
        let systemImage: String

        /// Detailed description or helper text
        let description: String

        /// Optional title for the action button. If `nil`, no button is shown.
        let buttonTitle: String?

        /// Accessibility identifier for UI testing
        let accessibilityID: String

        /// Creates a configuration for an empty state view.
        /// - Parameters:
        ///   - title: The main title text
        ///   - systemImage: SF Symbol name for the icon
        ///   - description: Detailed description or helper text
        ///   - buttonTitle: Optional title for the action button
        ///   - accessibilityID: Accessibility identifier for UI testing
        init(
            title: String,
            systemImage: String,
            description: String,
            buttonTitle: String? = nil,
            accessibilityID: String = "EmptyStateView"
        ) {
            self.title = title
            self.systemImage = systemImage
            self.description = description
            self.buttonTitle = buttonTitle
            self.accessibilityID = accessibilityID
        }
    }
}

// MARK: - Presets

extension EmptyStateView {
    /// Preset configurations for common empty state scenarios.
    ///
    /// These presets provide ready-to-use configurations for frequent use cases,
    /// ensuring consistency across the application.
    ///
    /// ## Available Presets
    /// - ``noItems``: Empty list state with "Add Item" suggestion
    /// - ``noSelection``: Detail view placeholder when nothing is selected
    /// - ``noSearchResults(_:)``: Search results empty state with query context
    /// - ``error(_:)``: Error display with recovery suggestions from ``AppError``
    /// - ``custom(_:)``: Wrapper for custom configurations
    enum Preset {
        /// Displayed when a list contains no items.
        /// Suggests using the + button or ⌘N keyboard shortcut.
        case noItems

        /// Displayed in detail views when no item is selected.
        /// Prompts user to select an item from the sidebar.
        case noSelection

        /// Displayed when a search query returns no results.
        /// - Parameter query: The search query that returned no results
        case noSearchResults(String)

        /// Displayed when an error occurs during an operation.
        /// - Parameter error: The ``AppError`` containing error details and recovery suggestions
        case error(AppError)

        /// Allows using a custom configuration as a preset.
        /// - Parameter configuration: The custom configuration to use
        case custom(Configuration)

        /// Converts the preset into its corresponding configuration.
        var configuration: Configuration {
            switch self {
            case .noItems:
                Configuration(
                    title: "No Items",
                    systemImage: "tray",
                    description: "Click the + button or press ⌘N to add an item.",
                    buttonTitle: "Add Item",
                    accessibilityID: "EmptyStateNoItems"
                )

            case .noSelection:
                Configuration(
                    title: "Select an Item",
                    systemImage: "doc.text",
                    description: "Choose an item from the sidebar to view its details.",
                    accessibilityID: "EmptyStateNoSelection"
                )

            case let .noSearchResults(query):
                Configuration(
                    title: "No Results",
                    systemImage: "magnifyingglass",
                    description: "No items match \"\(query)\". Try a different search term.",
                    accessibilityID: "EmptyStateNoSearchResults"
                )

            case let .error(appError):
                Configuration(
                    title: appError.errorDescription ?? "Error",
                    systemImage: "exclamationmark.triangle",
                    description: appError.recoverySuggestion ?? "Please try again.",
                    buttonTitle: "Try Again",
                    accessibilityID: "EmptyStateError"
                )

            case let .custom(config):
                config
            }
        }
    }
}

// MARK: - Preview

#Preview("No Items") {
    EmptyStateView(.noItems) {
        // Action placeholder for preview
    }
    .frame(width: 400, height: 300)
}

#Preview("No Selection") {
    EmptyStateView(.noSelection)
        .frame(width: 400, height: 300)
}

#Preview("No Search Results") {
    EmptyStateView(.noSearchResults("test query"))
        .frame(width: 400, height: 300)
}

#Preview("Error State") {
    EmptyStateView(.error(.fetchFailed(NSError(domain: "", code: -1)))) {
        // Retry action placeholder for preview
    }
    .frame(width: 400, height: 300)
}

#Preview("Custom") {
    EmptyStateView(
        configuration: EmptyStateView.Configuration(
            title: "Welcome",
            systemImage: "star.fill",
            description: "Get started by creating your first project.",
            buttonTitle: "Create Project"
        )
    ) {
        // Create action placeholder for preview
    }
    .frame(width: 400, height: 300)
}
