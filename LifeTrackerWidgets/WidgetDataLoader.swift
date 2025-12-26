import Foundation

/// Loads data from App Groups shared container for widgets
struct WidgetDataLoader {
    private static let appGroupIdentifier = "group.com.lifetracker.shared"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Medications

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

    static func loadMedicationsData() -> MedicationsWidgetData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "medicationsWidgetData"),
              let decoded = try? JSONDecoder().decode(MedicationsWidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }

    // MARK: - Workouts

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

    static func loadWorkoutsData() -> WorkoutsWidgetData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "workoutsWidgetData"),
              let decoded = try? JSONDecoder().decode(WorkoutsWidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }
}
