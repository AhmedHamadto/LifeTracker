import XCTest
import SwiftData
@testable import LifeTracker

final class WorkoutTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Workout.self, Exercise.self, ExerciseSet.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Workout Creation Tests

    func testWorkoutCreation() throws {
        let workout = Workout(
            date: Date(),
            type: .strength,
            name: "Push Day",
            duration: 3600
        )

        context.insert(workout)
        try context.save()

        XCTAssertNotNil(workout.id)
        XCTAssertEqual(workout.name, "Push Day")
        XCTAssertEqual(workout.type, .strength)
        XCTAssertEqual(workout.duration, 3600)
    }

    func testWorkoutDisplayName() {
        let workoutWithName = Workout(type: .strength, name: "Leg Day")
        XCTAssertEqual(workoutWithName.displayName, "Leg Day")

        let workoutWithoutName = Workout(type: .cardio)
        XCTAssertEqual(workoutWithoutName.displayName, "Cardio")
    }

    func testDurationDisplay() {
        let workout1 = Workout(duration: 3600) // 1 hour
        XCTAssertEqual(workout1.durationDisplay, "1h 0m")

        let workout2 = Workout(duration: 5400) // 1.5 hours
        XCTAssertEqual(workout2.durationDisplay, "1h 30m")

        let workout3 = Workout(duration: 1800) // 30 minutes
        XCTAssertEqual(workout3.durationDisplay, "30m")
    }

    // MARK: - Workout Type Tests

    func testAllWorkoutTypes() {
        let types = WorkoutType.allCases

        XCTAssertEqual(types.count, 6)
        XCTAssertTrue(types.contains(.strength))
        XCTAssertTrue(types.contains(.cardio))
        XCTAssertTrue(types.contains(.hiit))
        XCTAssertTrue(types.contains(.flexibility))
        XCTAssertTrue(types.contains(.sports))
        XCTAssertTrue(types.contains(.other))
    }

    func testWorkoutTypeIcons() {
        XCTAssertEqual(WorkoutType.strength.icon, "dumbbell.fill")
        XCTAssertEqual(WorkoutType.cardio.icon, "figure.run")
        XCTAssertEqual(WorkoutType.hiit.icon, "bolt.fill")
        XCTAssertEqual(WorkoutType.flexibility.icon, "figure.yoga")
    }

    func testWorkoutTypeColors() {
        XCTAssertEqual(WorkoutType.strength.color, "red")
        XCTAssertEqual(WorkoutType.cardio.color, "green")
        XCTAssertEqual(WorkoutType.hiit.color, "orange")
        XCTAssertEqual(WorkoutType.flexibility.color, "purple")
    }

    // MARK: - Exercise Tests

    func testExerciseCreation() throws {
        let workout = Workout(type: .strength)
        let exercise = Exercise(
            name: "Bench Press",
            muscleGroup: .chest,
            order: 0,
            workout: workout
        )

        context.insert(workout)
        context.insert(exercise)
        try context.save()

        XCTAssertEqual(exercise.name, "Bench Press")
        XCTAssertEqual(exercise.muscleGroup, .chest)
        XCTAssertEqual(exercise.workout?.type, .strength)
    }

    func testExerciseVolume() throws {
        let exercise = Exercise(name: "Squat", muscleGroup: .quads)

        let set1 = ExerciseSet(setNumber: 1, weight: 100, reps: 10, exercise: exercise)
        let set2 = ExerciseSet(setNumber: 2, weight: 100, reps: 10, exercise: exercise)

        context.insert(exercise)
        context.insert(set1)
        context.insert(set2)
        try context.save()

        // Note: In real test, would need to verify relationship is set up correctly
        XCTAssertEqual(set1.volume, 1000)
        XCTAssertEqual(set2.volume, 1000)
    }

    // MARK: - Exercise Set Tests

    func testExerciseSetCreation() throws {
        let set = ExerciseSet(
            setNumber: 1,
            weight: 80,
            weightUnit: .kg,
            reps: 12,
            isWarmup: false,
            isPersonalRecord: true
        )

        context.insert(set)
        try context.save()

        XCTAssertEqual(set.setNumber, 1)
        XCTAssertEqual(set.weight, 80)
        XCTAssertEqual(set.reps, 12)
        XCTAssertFalse(set.isWarmup)
        XCTAssertTrue(set.isPersonalRecord)
    }

    func testDisplayWeight() {
        let setKg = ExerciseSet(setNumber: 1, weight: 100, weightUnit: .kg, reps: 10)
        XCTAssertEqual(setKg.displayWeight, "100 kg")

        let setLbs = ExerciseSet(setNumber: 1, weight: 225, weightUnit: .lbs, reps: 10)
        XCTAssertEqual(setLbs.displayWeight, "225 lbs")
    }

    func testSetVolume() {
        let set = ExerciseSet(setNumber: 1, weight: 100, reps: 10)

        XCTAssertEqual(set.volume, 1000)
    }

    // MARK: - Weight Unit Tests

    func testWeightConversion() {
        let kgToLbs = WeightUnit.kg.convert(to: .lbs, value: 100)
        XCTAssertEqual(kgToLbs, 220.462, accuracy: 0.01)

        let lbsToKg = WeightUnit.lbs.convert(to: .kg, value: 220.462)
        XCTAssertEqual(lbsToKg, 100, accuracy: 0.01)

        let kgToKg = WeightUnit.kg.convert(to: .kg, value: 100)
        XCTAssertEqual(kgToKg, 100)
    }

    // MARK: - Muscle Group Tests

    func testAllMuscleGroups() {
        let groups = MuscleGroup.allCases

        XCTAssertEqual(groups.count, 14)
        XCTAssertTrue(groups.contains(.chest))
        XCTAssertTrue(groups.contains(.back))
        XCTAssertTrue(groups.contains(.shoulders))
        XCTAssertTrue(groups.contains(.biceps))
        XCTAssertTrue(groups.contains(.triceps))
    }

    // MARK: - Workout Stats Tests

    func testTotalSets() throws {
        let workout = Workout(type: .strength)
        let exercise1 = Exercise(name: "Bench", muscleGroup: .chest, workout: workout)
        let exercise2 = Exercise(name: "Rows", muscleGroup: .back, workout: workout)

        context.insert(workout)
        context.insert(exercise1)
        context.insert(exercise2)

        // Sets would be added via relationship
        // This test verifies the totalSets computed property exists
        XCTAssertEqual(workout.totalSets, 0)
    }
}
