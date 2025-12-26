import XCTest
import SwiftData
@testable import LifeTracker

final class BodyMeasurementTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([BodyMeasurement.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Creation Tests

    func testBodyMeasurementCreation() throws {
        let measurement = BodyMeasurement(
            date: Date(),
            weight: 75.5,
            weightUnit: .kg,
            bodyFatPercentage: 18.5,
            chest: 100,
            waist: 80,
            measurementUnit: .cm
        )

        context.insert(measurement)
        try context.save()

        XCTAssertNotNil(measurement.id)
        XCTAssertEqual(measurement.weight, 75.5)
        XCTAssertEqual(measurement.bodyFatPercentage, 18.5)
        XCTAssertEqual(measurement.chest, 100)
        XCTAssertEqual(measurement.waist, 80)
    }

    // MARK: - Display Tests

    func testDisplayWeight() {
        let measurement = BodyMeasurement(weight: 75.5, weightUnit: .kg)

        XCTAssertNotNil(measurement.displayWeight)
        XCTAssertTrue(measurement.displayWeight!.contains("75.5"))
        XCTAssertTrue(measurement.displayWeight!.contains("kg"))
    }

    func testDisplayWeightLbs() {
        let measurement = BodyMeasurement(weight: 165.0, weightUnit: .lbs)

        XCTAssertNotNil(measurement.displayWeight)
        XCTAssertTrue(measurement.displayWeight!.contains("165"))
        XCTAssertTrue(measurement.displayWeight!.contains("lbs"))
    }

    func testDisplayWeightNil() {
        let measurement = BodyMeasurement()

        XCTAssertNil(measurement.displayWeight)
    }

    func testDisplayBodyFat() {
        let measurement = BodyMeasurement(bodyFatPercentage: 18.5)

        XCTAssertNotNil(measurement.displayBodyFat)
        XCTAssertTrue(measurement.displayBodyFat!.contains("18.5"))
        XCTAssertTrue(measurement.displayBodyFat!.contains("%"))
    }

    func testDisplayBodyFatNil() {
        let measurement = BodyMeasurement()

        XCTAssertNil(measurement.displayBodyFat)
    }

    // MARK: - Measurements Summary Tests

    func testMeasurementsSummary() {
        let measurement = BodyMeasurement(
            chest: 100,
            waist: 80,
            hips: 95,
            bicepLeft: 35,
            bicepRight: 36
        )

        let summary = measurement.measurementsSummary

        XCTAssertEqual(summary["Chest"], 100)
        XCTAssertEqual(summary["Waist"], 80)
        XCTAssertEqual(summary["Hips"], 95)
        XCTAssertEqual(summary["Left Bicep"], 35)
        XCTAssertEqual(summary["Right Bicep"], 36)
    }

    func testMeasurementsSummaryPartial() {
        let measurement = BodyMeasurement(chest: 100, waist: 80)

        let summary = measurement.measurementsSummary

        XCTAssertEqual(summary.count, 2)
        XCTAssertEqual(summary["Chest"], 100)
        XCTAssertEqual(summary["Waist"], 80)
        XCTAssertNil(summary["Hips"])
    }

    func testMeasurementsSummaryEmpty() {
        let measurement = BodyMeasurement()

        XCTAssertTrue(measurement.measurementsSummary.isEmpty)
    }

    // MARK: - Unit Conversion Tests

    func testMeasurementUnitConversion() {
        let cmToInches = MeasurementUnit.cm.convert(to: .inches, value: 100)
        XCTAssertEqual(cmToInches, 39.37, accuracy: 0.01)

        let inchesToCm = MeasurementUnit.inches.convert(to: .cm, value: 39.37)
        XCTAssertEqual(inchesToCm, 100, accuracy: 0.1)

        let cmToCm = MeasurementUnit.cm.convert(to: .cm, value: 100)
        XCTAssertEqual(cmToCm, 100)
    }

    // MARK: - Photo Tests

    func testMeasurementWithPhoto() {
        let photoData = "test image data".data(using: .utf8)!
        let measurement = BodyMeasurement(photo: photoData)

        XCTAssertNotNil(measurement.photo)
        XCTAssertEqual(measurement.photo, photoData)
    }

    // MARK: - Notes Tests

    func testMeasurementWithNotes() {
        let measurement = BodyMeasurement(notes: "Morning measurement, fasted")

        XCTAssertEqual(measurement.notes, "Morning measurement, fasted")
    }
}
