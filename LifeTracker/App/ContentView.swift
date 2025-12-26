import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .dashboard

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    var body: some View {
        if hasCompletedOnboarding || isUITesting {
            mainTabView
        } else {
            OnboardingView()
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            DocumentsListView()
                .tabItem {
                    Label("Documents", systemImage: "doc.fill")
                }
                .tag(Tab.documents)

            MedicationsListView()
                .tabItem {
                    Label("Meds", systemImage: "pills.fill")
                }
                .tag(Tab.medications)

            InventoryListView()
                .tabItem {
                    Label("Inventory", systemImage: "archivebox.fill")
                }
                .tag(Tab.inventory)

            HealthView()
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
                .tag(Tab.health)
        }
        .tint(.accentColor)
    }
}

enum Tab: String, CaseIterable {
    case dashboard
    case documents
    case medications
    case inventory
    case health
}

#Preview {
    ContentView()
        .modelContainer(for: [Document.self, Medication.self, InventoryItem.self, Workout.self], inMemory: true)
}
