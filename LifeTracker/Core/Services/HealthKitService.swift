import Foundation
import HealthKit

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var isAvailable = false

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType()
        ]

        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit authorization error: \(error)")
            return false
        }
    }

    // MARK: - Read Data

    func fetchLatestWeight() async -> Double? {
        guard isAvailable else { return nil }

        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }

            healthStore.execute(query)
        }
    }

    func fetchLatestBodyFat() async -> Double? {
        guard isAvailable else { return nil }

        let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyFatType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let bodyFat = sample.quantity.doubleValue(for: .percent()) * 100
                continuation.resume(returning: bodyFat)
            }

            healthStore.execute(query)
        }
    }

    func fetchWeightHistory(days: Int = 30) async -> [(date: Date, weight: Double)] {
        guard isAvailable else { return [] }

        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = samples.map { sample in
                    (date: sample.startDate, weight: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                }
                continuation.resume(returning: results)
            }

            healthStore.execute(query)
        }
    }

    func fetchTodaySteps() async -> Int {
        guard isAvailable else { return 0 }

        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let steps = Int(sum.doubleValue(for: .count()))
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    func fetchTodayCaloriesBurned() async -> Int {
        guard isAvailable else { return 0 }

        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let calories = Int(sum.doubleValue(for: .kilocalorie()))
                continuation.resume(returning: calories)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Write Data

    func saveWeight(_ weight: Double, unit: WeightUnit = .kg, date: Date = Date()) async throws {
        guard isAvailable else { throw HealthKitError.notAvailable }

        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let weightInKg = unit == .lbs ? weight / 2.20462 : weight
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)

        try await healthStore.save(sample)
    }

    func saveBodyFat(_ percentage: Double, date: Date = Date()) async throws {
        guard isAvailable else { throw HealthKitError.notAvailable }

        let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let quantity = HKQuantity(unit: .percent(), doubleValue: percentage / 100)
        let sample = HKQuantitySample(type: bodyFatType, quantity: quantity, start: date, end: date)

        try await healthStore.save(sample)
    }

    func saveWorkout(_ workout: Workout) async throws {
        guard isAvailable else { throw HealthKitError.notAvailable }

        let workoutType = convertToHKWorkoutType(workout.type)
        let hkWorkout = HKWorkout(
            activityType: workoutType,
            start: workout.date,
            end: workout.date.addingTimeInterval(workout.duration),
            duration: workout.duration,
            totalEnergyBurned: workout.caloriesBurned.map { HKQuantity(unit: .kilocalorie(), doubleValue: Double($0)) },
            totalDistance: nil,
            metadata: [
                "LifeTrackerWorkoutId": workout.id.uuidString,
                "WorkoutName": workout.displayName
            ]
        )

        try await healthStore.save(hkWorkout)
    }

    private func convertToHKWorkoutType(_ type: WorkoutType) -> HKWorkoutActivityType {
        switch type {
        case .strength: return .traditionalStrengthTraining
        case .cardio: return .running
        case .hiit: return .highIntensityIntervalTraining
        case .flexibility: return .yoga
        case .sports: return .mixedCardio
        case .other: return .other
        }
    }
}

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .saveFailed:
            return "Failed to save data to HealthKit"
        }
    }
}
