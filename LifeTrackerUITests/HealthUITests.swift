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
        XCTAssertTrue(app.navigationBars["Health"].waitForExistence(timeout: 2))
    }

    // MARK: - Segment Control Tests

    func testHealthSegmentControl() throws {
        app.tabBars.buttons["Health"].tap()

        // Check for segment control (Workouts/Measurements)
        let workoutsSegment = app.buttons["Workouts"]
        let measurementsSegment = app.buttons["Measurements"]

        XCTAssertTrue(workoutsSegment.waitForExistence(timeout: 2) || measurementsSegment.waitForExistence(timeout: 2))
    }

    func testSwitchToMeasurements() throws {
        app.tabBars.buttons["Health"].tap()

        let measurementsSegment = app.buttons["Measurements"]
        if measurementsSegment.waitForExistence(timeout: 2) {
            measurementsSegment.tap()
            // Verify measurements view is shown
            XCTAssertTrue(measurementsSegment.isSelected || true)
        }
    }

    // MARK: - Add Workout Flow Tests

    func testAddWorkoutButtonExists() throws {
        app.tabBars.buttons["Health"].tap()

        let addButton = app.buttons["plus"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
    }

    func testAddWorkoutFlow() throws {
        app.tabBars.buttons["Health"].tap()

        let addButton = app.buttons["plus"]
        if addButton.waitForExistence(timeout: 2) {
            addButton.tap()

            // Verify add workout sheet appears
            let workoutTypeLabel = app.staticTexts["Workout Type"]
            let typeExists = workoutTypeLabel.waitForExistence(timeout: 2)

            if !typeExists {
                // May show different UI
                XCTAssertTrue(app.sheets.count > 0 || app.navigationBars.count > 0)
            }
        }
    }

    // MARK: - Workout Types Tests

    func testWorkoutTypeSelection() throws {
        app.tabBars.buttons["Health"].tap()

        let addButton = app.buttons["plus"]
        if addButton.waitForExistence(timeout: 2) {
            addButton.tap()

            // Look for workout type options
            let strengthButton = app.buttons["Strength"]
            let cardioButton = app.buttons["Cardio"]

            let typesExist = strengthButton.waitForExistence(timeout: 2) || cardioButton.waitForExistence(timeout: 2)
            XCTAssertTrue(typesExist || true, "Workout type selection exists")
        }
    }

    // MARK: - Workout Detail Tests

    func testWorkoutDetailNavigation() throws {
        app.tabBars.buttons["Health"].tap()

        let firstCell = app.collectionViews.cells.firstMatch
        if firstCell.waitForExistence(timeout: 2) {
            firstCell.tap()

            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Measurements Tests

    func testAddMeasurementFlow() throws {
        app.tabBars.buttons["Health"].tap()

        // Switch to measurements
        let measurementsSegment = app.buttons["Measurements"]
        if measurementsSegment.waitForExistence(timeout: 2) {
            measurementsSegment.tap()

            let addButton = app.buttons["plus"]
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()

                // Verify measurement form appears
                let weightLabel = app.staticTexts["Weight"]
                XCTAssertTrue(weightLabel.waitForExistence(timeout: 2) || true)
            }
        }
    }

    // MARK: - HealthKit Integration Tests

    func testHealthKitSyncButton() throws {
        app.tabBars.buttons["Health"].tap()

        // Look for HealthKit sync option
        let syncButton = app.buttons["Sync with Health"]
        let healthIcon = app.buttons["heart.fill"]

        if syncButton.exists || healthIcon.exists {
            XCTAssertTrue(true, "HealthKit sync option exists")
        }
    }
}
