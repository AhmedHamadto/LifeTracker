import SwiftUI
import SwiftData

struct MedicationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]

    @State private var searchText = ""
    @State private var showingAddMedication = false
    @State private var showActiveOnly = true

    var body: some View {
        NavigationStack {
            Group {
                if medications.isEmpty {
                    EmptyStateView(
                        icon: "pills.fill",
                        title: "No Medications",
                        message: "Add your medications to track schedules and never miss a dose",
                        buttonTitle: "Add Medication"
                    ) {
                        showingAddMedication = true
                    }
                } else {
                    medicationsList
                }
            }
            .navigationTitle("Medications")
            .searchable(text: $searchText, prompt: "Search medications")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showActiveOnly.toggle()
                    } label: {
                        HStack {
                            Image(systemName: showActiveOnly ? "checkmark.circle.fill" : "circle")
                            Text("Active Only")
                                .font(.caption)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView()
            }
        }
    }

    private var medicationsList: some View {
        List {
            // Today's Schedule Section
            if !todaysPendingMedications.isEmpty {
                Section {
                    ForEach(todaysPendingMedications) { medication in
                        MedicationScheduleRow(medication: medication)
                    }
                } header: {
                    Text("Today's Schedule")
                }
            }

            // All Medications Section
            Section {
                ForEach(filteredMedications) { medication in
                    NavigationLink(destination: MedicationDetailView(medication: medication)) {
                        MedicationRowView(medication: medication)
                    }
                }
                .onDelete(perform: deleteMedications)
            } header: {
                Text("All Medications")
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filteredMedications: [Medication] {
        var result = medications

        if showActiveOnly {
            result = result.filter { $0.isActive }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private var todaysPendingMedications: [Medication] {
        medications.filter { medication in
            medication.isActive && medication.nextDoseTime != nil
        }
    }

    private func deleteMedications(at offsets: IndexSet) {
        for index in offsets {
            let medication = filteredMedications[index]
            modelContext.delete(medication)
        }
    }
}

struct MedicationScheduleRow: View {
    let medication: Medication
    @State private var isCompleted = false

    var body: some View {
        HStack {
            Button {
                isCompleted.toggle()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? Theme.success : .secondary)
            }
            .buttonStyle(.plain)

            Circle()
                .fill(Color.module(medication.colorName))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading) {
                Text(medication.name)
                    .font(.headline)
                    .strikethrough(isCompleted)
                Text(medication.dosageDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let nextDose = medication.nextDoseTime {
                Text(nextDose, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
            }
        }
    }
}

struct MedicationRowView: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Color.module(medication.colorName))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(medication.name)
                        .font(.headline)

                    if !medication.isActive {
                        Text("Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text("\(medication.dosageDisplay) • \(medication.frequency.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if medication.needsRefill {
                    Label("Refill needed", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var dosage = ""
    @State private var dosageUnit: DosageUnit = .mg
    @State private var frequency: MedicationFrequency = .daily
    @State private var times: [Date] = [Date()]
    @State private var instructions = ""
    @State private var selectedColor = "blue"

    private let colors = ["blue", "green", "red", "purple", "orange", "pink", "mint", "indigo"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Name", text: $name)

                    HStack {
                        TextField("Dosage", text: $dosage)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $dosageUnit) {
                            ForEach(DosageUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(MedicationFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    ForEach(times.indices, id: \.self) { index in
                        DatePicker("Time \(index + 1)", selection: $times[index], displayedComponents: .hourAndMinute)
                    }

                    if frequency.timesPerDay > times.count {
                        Button("Add Time") {
                            times.append(Date())
                        }
                    }
                }

                Section("Additional Info") {
                    TextField("Instructions (optional)", text: $instructions, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color.module(color))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.caption)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }

    private func saveMedication() {
        let medication = Medication(
            name: name,
            dosage: dosage,
            dosageUnit: dosageUnit,
            frequency: frequency,
            times: times,
            instructions: instructions.isEmpty ? nil : instructions,
            colorName: selectedColor
        )
        modelContext.insert(medication)

        // Schedule notifications
        Task {
            await NotificationService.shared.scheduleMedicationReminders(for: medication)
        }

        dismiss()
    }
}

#Preview {
    MedicationsListView()
        .modelContainer(for: Medication.self, inMemory: true)
}
