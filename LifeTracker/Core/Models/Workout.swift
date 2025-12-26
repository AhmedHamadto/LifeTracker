import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var date: Date
    var type: WorkoutType
    var name: String?
    var duration: TimeInterval
    var caloriesBurned: Int?
    var notes: String?
    var rating: Int?
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var exercises: [Exercise]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: WorkoutType = .strength,
        name: String? = nil,
        duration: TimeInterval = 0,
        caloriesBurned: Int? = nil,
        notes: String? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.notes = notes
        self.rating = rating
        self.createdAt = Date()
        self.exercises = []
    }

    var displayName: String {
        name ?? type.rawValue
    }

    var durationDisplay: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.totalVolume
        }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case strength = "Strength"
    case cardio = "Cardio"
    case hiit = "HIIT"
    case flexibility = "Flexibility"
    case sports = "Sports"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .hiit: return "bolt.fill"
        case .flexibility: return "figure.yoga"
        case .sports: return "sportscourt.fill"
        case .other: return "figure.mixed.cardio"
        }
    }

    var color: String {
        switch self {
        case .strength: return "red"
        case .cardio: return "green"
        case .hiit: return "orange"
        case .flexibility: return "purple"
        case .sports: return "blue"
        case .other: return "gray"
        }
    }
}
