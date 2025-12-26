import Foundation
import WidgetKit

/// Service for sharing data between the main app and widgets via App Groups
actor WidgetDataService {
    static let shared = WidgetDataService()

    private let appGroupIdentifier = "group.com.lifetracker.shared"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Medications Data

    struct MedicationWidgetInfo: Codable {
        let id: String
        let name: String
        let dosage: String
        let nextDoseTime: Date?
        let colorName: String
        let isTaken: Bool
    }

    struct MedicationsWidgetData: Codable {
        let medications: [MedicationWidgetInfo]
        let completedToday: Int
        let totalToday: Int
        let lastUpdated: Date
    }

    func saveMedicationsData(_ data: MedicationsWidgetData) {
        guard let defaults = sharedDefaults else { return }

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "medicationsWidgetData")
        }

        // Reload widgets
        WidgetCenter.shared.reloadTimelines(ofKind: "MedicationsWidget")
    }

    func loadMedicationsData() -> MedicationsWidgetData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "medicationsWidgetData"),
              let decoded = try? JSONDecoder().decode(MedicationsWidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }

    // MARK: - Workouts Data

    struct WorkoutWidgetInfo: Codable {
        let id: String
        let name: String
        let type: String
        let date: Date
        let duration: TimeInterval
        let exerciseCount: Int
        let colorName: String
        let icon: String
    }

    struct WorkoutsWidgetData: Codable {
        let weeklyWorkouts: Int
        let weeklyDuration: TimeInterval
        let weeklyGoal: Int
        let recentWorkouts: [WorkoutWidgetInfo]
        let streak: Int
        let lastUpdated: Date
    }

    func saveWorkoutsData(_ data: WorkoutsWidgetData) {
        guard let defaults = sharedDefaults else { return }

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "workoutsWidgetData")
        }

        // Reload widgets
        WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutsWidget")
    }

    func loadWorkoutsData() -> WorkoutsWidgetData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "workoutsWidgetData"),
              let decoded = try? JSONDecoder().decode(WorkoutsWidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }

    // MARK: - Update from Models

    func updateMedicationsWidget(medications: [Medication]) async {
        let today = Calendar.current.startOfDay(for: Date())

        var medicationInfos: [MedicationWidgetInfo] = []
        var completedToday = 0
        var totalToday = 0

        for medication in medications where medication.isActive {
            let todayLogs = medication.logs.filter {
                Calendar.current.isDate($0.scheduledTime, inSameDayAs: today)
            }

            let taken = todayLogs.filter { $0.status == .taken }.count
            completedToday += taken
            totalToday += medication.times.count

            // Get next pending dose
            let nextDose = medication.nextDoseTime
            let isTaken = todayLogs.contains { $0.status == .taken }

            let info = MedicationWidgetInfo(
                id: medication.id.uuidString,
                name: medication.name,
                dosage: medication.dosageDisplay,
                nextDoseTime: nextDose,
                colorName: medication.colorName,
                isTaken: isTaken
            )
            medicationInfos.append(info)
        }

        // Sort by next dose time
        medicationInfos.sort { ($0.nextDoseTime ?? .distantFuture) < ($1.nextDoseTime ?? .distantFuture) }

        let data = MedicationsWidgetData(
            medications: medicationInfos,
            completedToday: completedToday,
            totalToday: totalToday,
            lastUpdated: Date()
        )

        saveMedicationsData(data)
    }

    func updateWorkoutsWidget(workouts: [Workout]) async {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

        // This week's workouts
        let thisWeekWorkouts = workouts.filter { $0.date >= startOfWeek }
        let weeklyDuration = thisWeekWorkouts.reduce(0) { $0 + $1.duration }

        // Recent workouts (last 5)
        let recentWorkouts = workouts
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { workout in
                WorkoutWidgetInfo(
                    id: workout.id.uuidString,
                    name: workout.displayName,
                    type: workout.type.rawValue,
                    date: workout.date,
                    duration: workout.duration,
                    exerciseCount: workout.exercises.count,
                    colorName: workout.type.color,
                    icon: workout.type.icon
                )
            }

        // Calculate streak
        let streak = calculateStreak(from: workouts)

        let data = WorkoutsWidgetData(
            weeklyWorkouts: thisWeekWorkouts.count,
            weeklyDuration: weeklyDuration,
            weeklyGoal: 5, // Could be configurable
            recentWorkouts: Array(recentWorkouts),
            streak: streak,
            lastUpdated: Date()
        )

        saveWorkoutsData(data)
    }

    private func calculateStreak(from workouts: [Workout]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check if there's a workout today
        let hasWorkoutToday = workouts.contains { calendar.isDate($0.date, inSameDayAs: currentDate) }

        if !hasWorkoutToday {
            // If no workout today, start checking from yesterday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        // Count consecutive days with workouts
        while true {
            let hasWorkout = workouts.contains { calendar.isDate($0.date, inSameDayAs: currentDate) }

            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Reload Widgets

    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func reloadMedicationsWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "MedicationsWidget")
    }

    func reloadWorkoutsWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutsWidget")
    }
}

