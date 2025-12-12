import Foundation
@testable import MacAppTemplate
import Testing

// MARK: - EmptyStateView Tests

/// Tests for `EmptyStateView.Configuration` and `EmptyStateView.Preset`.
struct EmptyStateViewTests {
    // MARK: - Preset Configuration Tests

    @Test("noItems preset has correct configuration", .tags(.view))
    func noItemsPresetHasCorrectConfiguration() {
        let config = EmptyStateView.Preset.noItems.configuration

        #expect(config.title == "No Items")
        #expect(config.systemImage == "tray")
        #expect(config.description.contains("⌘N"))
        #expect(config.buttonTitle == "Add Item")
        #expect(config.accessibilityID == "EmptyStateNoItems")
    }

    @Test("noSelection preset has correct configuration", .tags(.view))
    func noSelectionPresetHasCorrectConfiguration() {
        let config = EmptyStateView.Preset.noSelection.configuration

        #expect(config.title == "Select an Item")
        #expect(config.systemImage == "doc.text")
        #expect(config.description.contains("sidebar"))
        #expect(config.buttonTitle == nil)
        #expect(config.accessibilityID == "EmptyStateNoSelection")
    }

    @Test("noSearchResults preset includes query", .tags(.view))
    func noSearchResultsPresetIncludesQuery() {
        let query = "test search"
        let config = EmptyStateView.Preset.noSearchResults(query).configuration

        #expect(config.title == "No Results")
        #expect(config.systemImage == "magnifyingglass")
        #expect(config.description.contains(query))
        #expect(config.buttonTitle == nil)
        #expect(config.accessibilityID == "EmptyStateNoSearchResults")
    }

    @Test("error preset uses AppError properties", .tags(.view))
    func errorPresetUsesAppErrorProperties() {
        let appError = AppError.fetchFailed(NSError(domain: "", code: -1))
        let config = EmptyStateView.Preset.error(appError).configuration

        #expect(config.title == appError.errorDescription)
        #expect(config.systemImage == "exclamationmark.triangle")
        #expect(config.description == appError.recoverySuggestion)
        #expect(config.buttonTitle == "Try Again")
        #expect(config.accessibilityID == "EmptyStateError")
    }

    @Test("custom preset passes through configuration", .tags(.view))
    func customPresetPassesThroughConfiguration() {
        let customConfig = EmptyStateView.Configuration(
            title: "Custom Title",
            systemImage: "star.fill",
            description: "Custom description",
            buttonTitle: "Custom Action",
            accessibilityID: "CustomID"
        )

        let config = EmptyStateView.Preset.custom(customConfig).configuration

        #expect(config.title == customConfig.title)
        #expect(config.systemImage == customConfig.systemImage)
        #expect(config.description == customConfig.description)
        #expect(config.buttonTitle == customConfig.buttonTitle)
        #expect(config.accessibilityID == customConfig.accessibilityID)
    }

    // MARK: - Configuration Tests

    @Test("Configuration initializes with all parameters", .tags(.view))
    func configurationInitializesWithAllParameters() {
        let config = EmptyStateView.Configuration(
            title: "Test Title",
            systemImage: "folder",
            description: "Test Description",
            buttonTitle: "Test Button",
            accessibilityID: "TestID"
        )

        #expect(config.title == "Test Title")
        #expect(config.systemImage == "folder")
        #expect(config.description == "Test Description")
        #expect(config.buttonTitle == "Test Button")
        #expect(config.accessibilityID == "TestID")
    }

    @Test("Configuration initializes with default values", .tags(.view))
    func configurationInitializesWithDefaults() {
        let config = EmptyStateView.Configuration(
            title: "Title",
            systemImage: "star",
            description: "Description"
        )

        #expect(config.buttonTitle == nil)
        #expect(config.accessibilityID == "EmptyStateView")
    }

    // MARK: - Error Preset Variations

    @Test("error preset handles different AppError cases", .tags(.view))
    func errorPresetHandlesDifferentCases() {
        let errors: [AppError] = [
            .fetchFailed(NSError(domain: "", code: 0)),
            .saveFailed(NSError(domain: "", code: 0)),
            .networkError(NSError(domain: "", code: 0)),
            .validationError("Validation failed"),
            .unauthorized,
            .notFound("Document"),
            .unknown(NSError(domain: "", code: 0)),
        ]

        for error in errors {
            let config = EmptyStateView.Preset.error(error).configuration

            #expect(!config.title.isEmpty, "Title should not be empty for \(error)")
            #expect(!config.description.isEmpty, "Description should not be empty for \(error)")
            #expect(config.buttonTitle == "Try Again")
        }
    }

    // MARK: - Search Results Variations

    @Test("noSearchResults handles empty query", .tags(.view))
    func noSearchResultsHandlesEmptyQuery() {
        let config = EmptyStateView.Preset.noSearchResults("").configuration

        #expect(config.title == "No Results")
        #expect(config.description.contains("\"\""))
    }

    @Test("noSearchResults handles special characters in query", .tags(.view))
    func noSearchResultsHandlesSpecialCharacters() {
        let query = "test <script>alert('xss')</script>"
        let config = EmptyStateView.Preset.noSearchResults(query).configuration

        #expect(config.description.contains(query))
    }
}
