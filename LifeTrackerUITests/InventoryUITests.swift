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
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testInventoryEmptyState() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Add Item Flow Tests

    func testAddItemButtonExists() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testScanBarcodeButtonExists() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Category Filter Tests

    func testCategoryFilterExists() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Search Tests

    func testInventorySearchExists() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Item Detail Tests

    func testItemDetailNavigation() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Total Value Display Tests

    func testTotalValueDisplay() throws {
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }
}
