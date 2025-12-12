import XCTest

final class MacAppTemplateUITests: XCTestCase {
    var app: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let application = XCUIApplication()
        application.launchArguments = ["--uitesting"]
        application.launch()
        app = application

        // Wait for app to be ready
        _ = application.windows.firstMatch.waitForExistence(timeout: 5)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private var application: XCUIApplication {
        guard let app else {
            fatalError("App should be initialized in setUpWithError()")
        }
        return app
    }

    // MARK: - App Launch

    @MainActor
    func testAppLaunches() throws {
        XCTAssertTrue(application.windows.firstMatch.exists, "App should have at least one window")
    }

    // MARK: - Empty State

    @MainActor
    func testEmptyStateShowsOnLaunch() throws {
        let noItemsText = application.staticTexts["No Items"]
        XCTAssertTrue(
            noItemsText.waitForExistence(timeout: 5),
            "Empty state should be visible when no items exist"
        )
    }

    // MARK: - Add Item

    @MainActor
    func testAddItemButton() throws {
        // Use firstMatch to handle nested button structure in toolbar
        let addButton = application.buttons["AddItemButton"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Item button should exist")

        addButton.click()

        // Wait for item details to appear (indicates item was created and selected)
        let detailsSection = application.staticTexts["Details"]
        XCTAssertTrue(
            detailsSection.waitForExistence(timeout: 5),
            "Details should appear after adding an item"
        )
    }

    @MainActor
    func testAddItemKeyboardShortcut() throws {
        application.typeKey("n", modifierFlags: .command)

        // Wait for item details to appear
        let detailsSection = application.staticTexts["Details"]
        XCTAssertTrue(
            detailsSection.waitForExistence(timeout: 5),
            "Details should appear after pressing ⌘N"
        )
    }

    // MARK: - Select Item

    @MainActor
    func testSelectItem() throws {
        // Add an item first
        application.typeKey("n", modifierFlags: .command)

        // Wait for sidebar to have the item
        let sidebar = application.outlines["SidebarList"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "Sidebar should exist")

        let firstRow = sidebar.cells.firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "Item row should exist")

        firstRow.click()

        // Verify detail view shows
        let detailsSection = application.staticTexts["Details"]
        XCTAssertTrue(
            detailsSection.waitForExistence(timeout: 5),
            "Detail view should show when item is selected"
        )
    }

    // MARK: - Delete Item

    @MainActor
    func testDeleteItem() throws {
        // Add an item
        application.typeKey("n", modifierFlags: .command)

        // Wait for item to be created
        let sidebar = application.outlines["SidebarList"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "Sidebar should exist")

        let firstRow = sidebar.cells.firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "Item should exist before deletion")

        // Select and delete
        firstRow.click()
        application.typeKey(.delete, modifierFlags: [])

        // Wait for empty state to reappear
        let noItemsText = application.staticTexts["No Items"]
        XCTAssertTrue(
            noItemsText.waitForExistence(timeout: 5),
            "Empty state should show after deleting the only item"
        )
    }
}
