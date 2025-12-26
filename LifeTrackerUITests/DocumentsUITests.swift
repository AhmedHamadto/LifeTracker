import XCTest

final class DocumentsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    func testNavigateToDocuments() throws {
        app.tabBars.buttons["Documents"].tap()
        XCTAssertTrue(app.navigationBars["Documents"].waitForExistence(timeout: 2))
    }

    func testDocumentsEmptyState() throws {
        app.tabBars.buttons["Documents"].tap()

        // Check for empty state or document list
        let emptyStateExists = app.staticTexts["No Documents Yet"].waitForExistence(timeout: 2)
        let documentsExist = app.collectionViews.cells.count > 0

        XCTAssertTrue(emptyStateExists || documentsExist)
    }

    // MARK: - Add Document Flow Tests

    func testScanDocumentButtonExists() throws {
        app.tabBars.buttons["Documents"].tap()

        // Look for scan/add button
        let addButton = app.buttons["plus"]
        let scanButton = app.buttons["Scan Document"]

        XCTAssertTrue(addButton.exists || scanButton.exists)
    }

    func testCategoryFilterExists() throws {
        app.tabBars.buttons["Documents"].tap()

        // Check for category picker or filter
        let allButton = app.buttons["All"]
        XCTAssertTrue(allButton.waitForExistence(timeout: 2))
    }

    // MARK: - Search Tests

    func testDocumentSearchExists() throws {
        app.tabBars.buttons["Documents"].tap()

        // Check for search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
    }

    func testSearchFunctionality() throws {
        app.tabBars.buttons["Documents"].tap()

        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 2) {
            searchField.tap()
            searchField.typeText("test")

            // Verify keyboard is shown and search is active
            XCTAssertTrue(app.keyboards.count > 0)

            // Dismiss keyboard
            app.buttons["Cancel"].tap()
        }
    }
}
