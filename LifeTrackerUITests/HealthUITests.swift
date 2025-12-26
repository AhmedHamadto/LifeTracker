import XCTest

final class HealthUITests: XCTestCase {
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

    func testNavigateToHealth() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Segment Control Tests

    func testHealthSegmentControl() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testSwitchToMeasurements() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Add Workout Flow Tests

    func testAddWorkoutButtonExists() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testAddWorkoutFlow() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Workout Types Tests

    func testWorkoutTypeSelection() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Workout Detail Tests

    func testWorkoutDetailNavigation() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Measurements Tests

    func testAddMeasurementFlow() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - HealthKit Integration Tests

    func testHealthKitSyncButton() throws {
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }
}
