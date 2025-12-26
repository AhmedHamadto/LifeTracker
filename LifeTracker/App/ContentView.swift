import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
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
                    Label("Medications", systemImage: "pills.fill")
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
