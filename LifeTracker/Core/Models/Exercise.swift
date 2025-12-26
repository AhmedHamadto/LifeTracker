import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var notes: String?
    var order: Int

    @Relationship(inverse: \Workout.exercises)
    var workout: Workout?

    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet]

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup = .other,
        notes: String? = nil,
        order: Int = 0,
        workout: Workout? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.notes = notes
        self.order = order
        self.workout = workout
        self.sets = []
    }

    var totalVolume: Double {
        sets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }

    var bestSet: ExerciseSet? {
        sets.max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }
}

@Model
final class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var weightUnit: WeightUnit
    var reps: Int
    var isWarmup: Bool
    var isPersonalRecord: Bool
    var notes: String?

    @Relationship(inverse: \Exercise.sets)
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double,
        weightUnit: WeightUnit = .kg,
        reps: Int,
        isWarmup: Bool = false,
        isPersonalRecord: Bool = false,
        notes: String? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.weightUnit = weightUnit
        self.reps = reps
        self.isWarmup = isWarmup
        self.isPersonalRecord = isPersonalRecord
        self.notes = notes
        self.exercise = exercise
    }

    var volume: Double {
        weight * Double(reps)
    }

    var displayWeight: String {
        "\(Int(weight)) \(weightUnit.rawValue)"
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case core = "Core"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.boxing"
        case .biceps, .triceps, .forearms: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        case .quads, .hamstrings, .glutes, .calves: return "figure.run"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "heart.fill"
        case .other: return "dumbbell.fill"
        }
    }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "kg"
    case lbs = "lbs"

    var id: String { rawValue }

    func convert(to unit: WeightUnit, value: Double) -> Double {
        if self == unit { return value }
        switch (self, unit) {
        case (.kg, .lbs): return value * 2.20462
        case (.lbs, .kg): return value / 2.20462
        default: return value
        }
    }
}
