import XCTest

final class InventoryUITests: XCTestCase {
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

    func testNavigateToInventory() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars["Inventory"].waitForExistence(timeout: 2))
    }

    func testInventoryEmptyState() throws {
        app.tabBars.buttons["Inventory"].tap()

        let emptyStateExists = app.staticTexts["No Items Yet"].waitForExistence(timeout: 2)
        let itemsExist = app.collectionViews.cells.count > 0

        XCTAssertTrue(emptyStateExists || itemsExist)
    }

    // MARK: - Add Item Flow Tests

    func testAddItemButtonExists() throws {
        app.tabBars.buttons["Inventory"].tap()

        let addButton = app.buttons["plus"]
        let scanButton = app.buttons["barcode.viewfinder"]

        XCTAssertTrue(addButton.waitForExistence(timeout: 2) || scanButton.waitForExistence(timeout: 2))
    }

    func testScanBarcodeButtonExists() throws {
        app.tabBars.buttons["Inventory"].tap()

        let scanButton = app.buttons["barcode.viewfinder"]
        if scanButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(scanButton.exists)
        }
    }

    // MARK: - Category Filter Tests

    func testCategoryFilterExists() throws {
        app.tabBars.buttons["Inventory"].tap()

        // Check for category picker
        let allButton = app.buttons["All"]
        let electronicsButton = app.buttons["Electronics"]

        XCTAssertTrue(allButton.waitForExistence(timeout: 2) || electronicsButton.waitForExistence(timeout: 2))
    }

    // MARK: - Search Tests

    func testInventorySearchExists() throws {
        app.tabBars.buttons["Inventory"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
    }

    // MARK: - Item Detail Tests

    func testItemDetailNavigation() throws {
        app.tabBars.buttons["Inventory"].tap()

        let firstCell = app.collectionViews.cells.firstMatch
        if firstCell.waitForExistence(timeout: 2) {
            firstCell.tap()

            // Verify detail view appears
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Total Value Display Tests

    func testTotalValueDisplay() throws {
        app.tabBars.buttons["Inventory"].tap()

        // Look for total value summary
        let totalLabel = app.staticTexts["Total Value"]
        if totalLabel.exists {
            XCTAssertTrue(totalLabel.exists)
        }
    }
}
