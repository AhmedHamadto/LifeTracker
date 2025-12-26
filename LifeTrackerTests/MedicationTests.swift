import XCTest
import SwiftData
@testable import LifeTracker

final class MedicationTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Medication.self, MedicationLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Creation Tests

    func testMedicationCreation() throws {
        let medication = Medication(
            name: "Vitamin D",
            dosage: "1000",
            dosageUnit: .mg,
            frequency: .daily,
            times: [Date()],
            colorName: "orange"
        )

        context.insert(medication)
        try context.save()

        XCTAssertNotNil(medication.id)
        XCTAssertEqual(medication.name, "Vitamin D")
        XCTAssertEqual(medication.dosage, "1000")
        XCTAssertEqual(medication.dosageUnit, .mg)
        XCTAssertTrue(medication.isActive)
    }

    func testDosageDisplay() {
        let medication = Medication(
            name: "Omega-3",
            dosage: "500",
            dosageUnit: .mg
        )

        XCTAssertEqual(medication.dosageDisplay, "500 mg")
    }

    func testDosageDisplayVariousUnits() {
        let testCases: [(DosageUnit, String)] = [
            (.mg, "100 mg"),
            (.g, "100 g"),
            (.ml, "100 ml"),
            (.tablets, "100 tablets"),
            (.capsules, "100 capsules"),
            (.drops, "100 drops"),
            (.puffs, "100 puffs"),
            (.units, "100 units")
        ]

        for (unit, expected) in testCases {
            let medication = Medication(name: "Test", dosage: "100", dosageUnit: unit)
            XCTAssertEqual(medication.dosageDisplay, expected)
        }
    }

    // MARK: - Refill Tests

    func testNeedsRefillTrue() {
        let medication = Medication(
            name: "Test Med",
            dosage: "10",
            times: [Date()],
            remainingCount: 5,
            refillReminderDays: 7
        )

        XCTAssertTrue(medication.needsRefill)
    }

    func testNeedsRefillFalse() {
        let medication = Medication(
            name: "Test Med",
            dosage: "10",
            times: [Date()],
            remainingCount: 30,
            refillReminderDays: 7
        )

        XCTAssertFalse(medication.needsRefill)
    }

    func testNeedsRefillNoCount() {
        let medication = Medication(
            name: "Test Med",
            dosage: "10",
            remainingCount: nil
        )

        XCTAssertFalse(medication.needsRefill)
    }

    // MARK: - Frequency Tests

    func testFrequencyTimesPerDay() {
        XCTAssertEqual(MedicationFrequency.asNeeded.timesPerDay, 0)
        XCTAssertEqual(MedicationFrequency.daily.timesPerDay, 1)
        XCTAssertEqual(MedicationFrequency.twiceDaily.timesPerDay, 2)
        XCTAssertEqual(MedicationFrequency.threeTimesDaily.timesPerDay, 3)
        XCTAssertEqual(MedicationFrequency.fourTimesDaily.timesPerDay, 4)
        XCTAssertEqual(MedicationFrequency.weekly.timesPerDay, 1)
        XCTAssertEqual(MedicationFrequency.monthly.timesPerDay, 1)
    }

    // MARK: - Next Dose Tests

    func testNextDoseTimeToday() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59

        let futureTime = calendar.date(from: components)!

        let medication = Medication(
            name: "Evening Med",
            dosage: "10",
            times: [futureTime]
        )

        XCTAssertNotNil(medication.nextDoseTime)
    }

    // MARK: - Log Tests

    func testMedicationLogCreation() throws {
        let medication = Medication(name: "Test", dosage: "10")
        let log = MedicationLog(
            scheduledTime: Date(),
            status: .pending,
            medication: medication
        )

        context.insert(medication)
        context.insert(log)
        try context.save()

        XCTAssertEqual(log.status, .pending)
        XCTAssertEqual(log.medication?.name, "Test")
    }

    func testMarkAsTaken() {
        let log = MedicationLog(scheduledTime: Date(), status: .pending)

        log.markAsTaken()

        XCTAssertEqual(log.status, .taken)
        XCTAssertNotNil(log.actualTime)
    }

    func testMarkAsSkipped() {
        let log = MedicationLog(scheduledTime: Date(), status: .pending)

        log.markAsSkipped(reason: "Felt nauseous")

        XCTAssertEqual(log.status, .skipped)
        XCTAssertEqual(log.notes, "Felt nauseous")
    }

    func testMarkAsMissed() {
        let log = MedicationLog(scheduledTime: Date(), status: .pending)

        log.markAsMissed()

        XCTAssertEqual(log.status, .missed)
    }

    // MARK: - Log Status Tests

    func testLogStatusIcons() {
        XCTAssertEqual(MedicationLogStatus.pending.icon, "clock.fill")
        XCTAssertEqual(MedicationLogStatus.taken.icon, "checkmark.circle.fill")
        XCTAssertEqual(MedicationLogStatus.skipped.icon, "forward.fill")
        XCTAssertEqual(MedicationLogStatus.missed.icon, "xmark.circle.fill")
    }

    func testLogStatusColors() {
        XCTAssertEqual(MedicationLogStatus.pending.color, "orange")
        XCTAssertEqual(MedicationLogStatus.taken.color, "green")
        XCTAssertEqual(MedicationLogStatus.skipped.color, "gray")
        XCTAssertEqual(MedicationLogStatus.missed.color, "red")
    }
}
