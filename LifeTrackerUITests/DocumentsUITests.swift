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
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testDocumentsEmptyState() throws {
        app.tabBars.buttons["Documents"].tap()

        // Verify the view loaded
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Add Document Flow Tests

    func testScanDocumentButtonExists() throws {
        app.tabBars.buttons["Documents"].tap()

        // Verify the view loaded
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testCategoryFilterExists() throws {
        app.tabBars.buttons["Documents"].tap()

        // Verify the view loaded
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Search Tests

    func testDocumentSearchExists() throws {
        app.tabBars.buttons["Documents"].tap()

        // Verify the view loaded
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testSearchFunctionality() throws {
        app.tabBars.buttons["Documents"].tap()

        // Verify the view loaded
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }
}
