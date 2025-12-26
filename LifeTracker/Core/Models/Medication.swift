import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID
    var name: String
    var dosage: String
    var dosageUnit: DosageUnit
    var frequency: MedicationFrequency
    var times: [Date]
    var instructions: String?
    var remainingCount: Int?
    var refillReminderDays: Int?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var colorName: String
    var notes: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var logs: [MedicationLog]

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        dosageUnit: DosageUnit = .mg,
        frequency: MedicationFrequency = .daily,
        times: [Date] = [],
        instructions: String? = nil,
        remainingCount: Int? = nil,
        refillReminderDays: Int? = 7,
        startDate: Date = Date(),
        endDate: Date? = nil,
        colorName: String = "blue",
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.dosageUnit = dosageUnit
        self.frequency = frequency
        self.times = times
        self.instructions = instructions
        self.remainingCount = remainingCount
        self.refillReminderDays = refillReminderDays
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.colorName = colorName
        self.notes = notes
        self.createdAt = Date()
        self.logs = []
    }

    var dosageDisplay: String {
        "\(dosage) \(dosageUnit.rawValue)"
    }

    var needsRefill: Bool {
        guard let remaining = remainingCount, let reminderDays = refillReminderDays else {
            return false
        }
        let dosesPerDay = times.count
        let daysRemaining = dosesPerDay > 0 ? remaining / dosesPerDay : remaining
        return daysRemaining <= reminderDays
    }

    var nextDoseTime: Date? {
        let now = Date()
        let calendar = Calendar.current

        let todayTimes = times.map { time -> Date in
            var components = calendar.dateComponents([.hour, .minute], from: time)
            components.year = calendar.component(.year, from: now)
            components.month = calendar.component(.month, from: now)
            components.day = calendar.component(.day, from: now)
            return calendar.date(from: components) ?? time
        }.sorted()

        if let nextToday = todayTimes.first(where: { $0 > now }) {
            return nextToday
        }

        if let firstTime = todayTimes.first {
            return calendar.date(byAdding: .day, value: 1, to: firstTime)
        }

        return nil
    }

    func todaysLogs() -> [MedicationLog] {
        let calendar = Calendar.current
        return logs.filter { calendar.isDateInToday($0.scheduledTime) }
    }

    var todayCompletionRate: Double {
        let todayLogs = todaysLogs()
        guard !todayLogs.isEmpty else { return 0 }
        let taken = todayLogs.filter { $0.status == .taken }.count
        return Double(taken) / Double(todayLogs.count)
    }
}

enum DosageUnit: String, Codable, CaseIterable, Identifiable {
    case mg = "mg"
    case g = "g"
    case ml = "ml"
    case tablets = "tablets"
    case capsules = "capsules"
    case drops = "drops"
    case puffs = "puffs"
    case units = "units"

    var id: String { rawValue }
}

enum MedicationFrequency: String, Codable, CaseIterable, Identifiable {
    case asNeeded = "As Needed"
    case daily = "Daily"
    case twiceDaily = "Twice Daily"
    case threeTimesDaily = "3x Daily"
    case fourTimesDaily = "4x Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"

    var id: String { rawValue }

    var timesPerDay: Int {
        switch self {
        case .asNeeded: return 0
        case .daily: return 1
        case .twiceDaily: return 2
        case .threeTimesDaily: return 3
        case .fourTimesDaily: return 4
        case .weekly, .biweekly, .monthly: return 1
        }
    }
}
