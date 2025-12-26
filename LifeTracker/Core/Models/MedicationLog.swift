import Foundation
import SwiftData

@Model
final class MedicationLog {
    var id: UUID
    var scheduledTime: Date
    var actualTime: Date?
    var status: MedicationLogStatus
    var notes: String?
    var createdAt: Date

    @Relationship(inverse: \Medication.logs)
    var medication: Medication?

    init(
        id: UUID = UUID(),
        scheduledTime: Date,
        actualTime: Date? = nil,
        status: MedicationLogStatus = .pending,
        notes: String? = nil,
        medication: Medication? = nil
    ) {
        self.id = id
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.status = status
        self.notes = notes
        self.createdAt = Date()
        self.medication = medication
    }

    func markAsTaken() {
        status = .taken
        actualTime = Date()
    }

    func markAsSkipped(reason: String? = nil) {
        status = .skipped
        notes = reason
    }

    func markAsMissed() {
        status = .missed
    }
}

enum MedicationLogStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "Pending"
    case taken = "Taken"
    case skipped = "Skipped"
    case missed = "Missed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .taken: return "checkmark.circle.fill"
        case .skipped: return "forward.fill"
        case .missed: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .taken: return "green"
        case .skipped: return "gray"
        case .missed: return "red"
        }
    }
}
