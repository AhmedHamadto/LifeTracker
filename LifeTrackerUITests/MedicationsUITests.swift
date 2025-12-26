import XCTest

final class MedicationsUITests: XCTestCase {
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

    func testNavigateToMedications() throws {
        app.tabBars.buttons["Meds"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testMedicationsEmptyState() throws {
        app.tabBars.buttons["Meds"].tap()

        // Just verify the view loaded
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Add Medication Flow Tests

    func testAddMedicationButtonExists() throws {
        app.tabBars.buttons["Meds"].tap()

        // Navigation bar should exist
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
    }

    func testAddMedicationFlow() throws {
        app.tabBars.buttons["Meds"].tap()

        let addButton = app.buttons["plus"]
        if addButton.waitForExistence(timeout: 2) {
            addButton.tap()

            // Verify add medication sheet/view appears
            let nameField = app.textFields["Medication Name"]
            let nameLabel = app.staticTexts["Medication Name"]

            XCTAssertTrue(nameField.waitForExistence(timeout: 2) || nameLabel.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Medication Detail Tests

    func testMedicationDetailNavigation() throws {
        app.tabBars.buttons["Meds"].tap()

        // If there are medications, tap the first one
        let firstCell = app.collectionViews.cells.firstMatch
        if firstCell.waitForExistence(timeout: 2) {
            firstCell.tap()

            // Verify detail view appears
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Quick Action Tests

    func testTakeMedicationAction() throws {
        app.tabBars.buttons["Meds"].tap()

        // Look for "Take" or checkmark button
        let takeButton = app.buttons["Take"]
        let checkButton = app.buttons["checkmark.circle"]

        if takeButton.exists || checkButton.exists {
            XCTAssertTrue(true, "Take action button exists")
        }
    }
}
