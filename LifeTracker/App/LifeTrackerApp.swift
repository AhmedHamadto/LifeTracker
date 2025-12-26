import SwiftUI
import SwiftData

@main
struct LifeTrackerApp: App {
    let modelContainer: ModelContainer

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    init() {
        do {
            let schema = Schema([
                Document.self,
                Folder.self,
                Medication.self,
                MedicationLog.self,
                InventoryItem.self,
                Workout.self,
                Exercise.self,
                ExerciseSet.self,
                BodyMeasurement.self
            ])

            let modelConfiguration: ModelConfiguration
            if Self.isRunningTests {
                // Use in-memory storage without CloudKit for testing
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
            } else {
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
            }

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
