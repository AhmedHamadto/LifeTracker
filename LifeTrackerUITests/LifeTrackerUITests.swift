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
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists)
        XCTAssertTrue(app.tabBars.buttons["Documents"].exists)
        XCTAssertTrue(app.tabBars.buttons["Medications"].exists)
        XCTAssertTrue(app.tabBars.buttons["Inventory"].exists)
        XCTAssertTrue(app.tabBars.buttons["Health"].exists)

        // Navigate through tabs
        app.tabBars.buttons["Documents"].tap()
        XCTAssertTrue(app.navigationBars["Documents"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Medications"].tap()
        XCTAssertTrue(app.navigationBars["Medications"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.navigationBars["Inventory"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars["Health"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Dashboard"].tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 2))
    }

    // MARK: - Dashboard Tests

    func testDashboardQuickActions() throws {
        // Verify quick action buttons exist
        XCTAssertTrue(app.buttons["Scan"].exists || app.buttons["scan"].exists)
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
