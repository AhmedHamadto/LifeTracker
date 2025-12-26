import XCTest

final class LifeTrackerUITests: XCTestCase {
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

    // MARK: - Tab Navigation Tests

    func testTabNavigation() throws {
        // Verify all tabs are visible
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Documents"].exists)
        XCTAssertTrue(app.tabBars.buttons["Meds"].exists)
        XCTAssertTrue(app.tabBars.buttons["Inventory"].exists)
        XCTAssertTrue(app.tabBars.buttons["Health"].exists)

        // Navigate through tabs
        app.tabBars.buttons["Documents"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))

        app.tabBars.buttons["Meds"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))

        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))

        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))

        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Dashboard Tests

    func testDashboardQuickActions() throws {
        // Dashboard should be visible on launch
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Settings Access Tests

    func testSettingsAccess() throws {
        // Tap settings button in Dashboard
        let settingsButton = app.buttons["gear"]
        if settingsButton.exists {
            settingsButton.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        }
    }
}
