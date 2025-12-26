import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [Document]
    @Query private var medications: [Medication]
    @Query private var inventoryItems: [InventoryItem]
    @Query private var workouts: [Workout]

    @State private var showingAddMenu = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Quick Actions
                    quickActionsSection

                    // Stats Overview
                    statsSection

                    // Today's Medications
                    if !activeMedications.isEmpty {
                        todaysMedicationsSection
                    }

                    // Expiring Documents
                    if !expiringDocuments.isEmpty {
                        expiringDocumentsSection
                    }

                    // Recent Workouts
                    if !recentWorkouts.isEmpty {
                        recentWorkoutsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("LifeTracker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMenu = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .confirmationDialog("Add New", isPresented: $showingAddMenu) {
                Button("Scan Document") {}
                Button("Add Medication") {}
                Button("Add Item") {}
                Button("Log Workout") {}
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Sections

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Quick Actions")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.lg) {
                    QuickActionButton(title: "Scan Doc", icon: "doc.viewfinder", color: Theme.documentsColor) {}
                    QuickActionButton(title: "Add Med", icon: "pills.fill", color: Theme.medicationsColor) {}
                    QuickActionButton(title: "Scan Item", icon: "barcode.viewfinder", color: Theme.inventoryColor) {}
                    QuickActionButton(title: "Log Workout", icon: "dumbbell.fill", color: Theme.healthColor) {}
                    QuickActionButton(title: "Measure", icon: "ruler", color: .orange) {}
                }
                .padding(.horizontal)
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Overview")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Documents",
                    value: "\(documents.count)",
                    icon: "doc.fill",
                    iconColor: Theme.documentsColor
                )

                StatCard(
                    title: "Medications",
                    value: "\(activeMedications.count)",
                    icon: "pills.fill",
                    iconColor: Theme.medicationsColor
                )

                StatCard(
                    title: "Items",
                    value: "\(inventoryItems.count)",
                    icon: "archivebox.fill",
                    iconColor: Theme.inventoryColor
                )

                StatCard(
                    title: "Workouts",
                    value: "\(thisMonthWorkouts.count)",
                    icon: "dumbbell.fill",
                    iconColor: Theme.healthColor
                )
            }
            .padding(.horizontal)
        }
    }

    private var todaysMedicationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Today's Medications", showSeeAll: true) {}

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(activeMedications.prefix(3)) { medication in
                    MedicationQuickCard(medication: medication)
                }
            }
            .padding(.horizontal)
        }
    }

    private var expiringDocumentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Expiring Soon", showSeeAll: true) {}

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(expiringDocuments.prefix(3)) { document in
                    ExpiringDocumentCard(document: document)
                }
            }
            .padding(.horizontal)
        }
    }

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Recent Workouts", showSeeAll: true) {}

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(recentWorkouts.prefix(3)) { workout in
                    WorkoutQuickCard(workout: workout)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Computed Properties

    private var activeMedications: [Medication] {
        medications.filter { $0.isActive }
    }

    private var expiringDocuments: [Document] {
        documents.filter { $0.isExpiringSoon }
    }

    private var recentWorkouts: [Workout] {
        workouts.sorted { $0.date > $1.date }
    }

    private var thisMonthWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        return workouts.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }
}

// MARK: - Supporting Views

struct MedicationQuickCard: View {
    let medication: Medication

    var body: some View {
        CardView(padding: Theme.Spacing.md) {
            HStack {
                Circle()
                    .fill(Color.module(medication.colorName))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading) {
                    Text(medication.name)
                        .font(.headline)
                    Text(medication.dosageDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let nextDose = medication.nextDoseTime {
                    Text(nextDose, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Button {
                    // Mark as taken
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(Theme.medicationsColor)
                }
            }
        }
    }
}

struct ExpiringDocumentCard: View {
    let document: Document

    var body: some View {
        CardView(padding: Theme.Spacing.md) {
            HStack {
                Image(systemName: document.category.icon)
                    .font(.title3)
                    .foregroundStyle(Color.module(document.category.color))

                VStack(alignment: .leading) {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(1)
                    if let expiry = document.expiryDate {
                        Text("Expires \(expiry, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct WorkoutQuickCard: View {
    let workout: Workout

    var body: some View {
        CardView(padding: Theme.Spacing.md) {
            HStack {
                Image(systemName: workout.type.icon)
                    .font(.title3)
                    .foregroundStyle(Color.module(workout.type.color))

                VStack(alignment: .leading) {
                    Text(workout.displayName)
                        .font(.headline)
                    Text("\(workout.exercises.count) exercises • \(workout.durationDisplay)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Document.self, Medication.self, InventoryItem.self, Workout.self], inMemory: true)
}
