import SwiftUI
import SwiftData

struct MedicationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var medication: Medication

    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingLogSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header Card
                VStack(spacing: Theme.Spacing.lg) {
                    Circle()
                        .fill(Color.module(medication.colorName))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "pills.fill")
                                .font(.system(size: 35))
                                .foregroundStyle(.white)
                        }

                    VStack(spacing: Theme.Spacing.xs) {
                        Text(medication.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(medication.dosageDisplay)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    // Status badges
                    HStack(spacing: Theme.Spacing.sm) {
                        StatusBadge(
                            text: medication.isActive ? "Active" : "Inactive",
                            color: medication.isActive ? .green : .gray
                        )

                        StatusBadge(
                            text: medication.frequency.rawValue,
                            color: .blue
                        )

                        if medication.needsRefill {
                            StatusBadge(
                                text: "Refill Needed",
                                color: .orange
                            )
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .padding(.horizontal)

                // Today's Progress
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Today's Progress")
                        .font(.headline)

                    let todayLogs = medication.todaysLogs()
                    if !todayLogs.isEmpty {
                        VStack(spacing: Theme.Spacing.sm) {
                            ForEach(todayLogs) { log in
                                LogRow(log: log)
                            }
                        }

                        // Progress bar
                        let completion = medication.todayCompletionRate
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            HStack {
                                Text("Completion")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(completion * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.secondaryBackground)
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(completion == 1.0 ? Color.green : Color.module(medication.colorName))
                                        .frame(width: geometry.size.width * completion, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    } else {
                        Text("No doses scheduled for today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .padding(.horizontal)

                // Schedule
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Schedule")
                        .font(.headline)

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(medication.times.indices, id: \.self) { index in
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(Color.module(medication.colorName))
                                Text(medication.times[index], style: .time)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .padding(.horizontal)

                // Instructions
                if let instructions = medication.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Instructions")
                            .font(.headline)

                        Text(instructions)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal)
                }

                // Inventory
                if let remaining = medication.remainingCount {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Inventory")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(remaining) doses")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }

                            Spacer()

                            if let reminder = medication.refillReminderDays {
                                VStack(alignment: .trailing) {
                                    Text("Refill Reminder")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(reminder) days before")
                                        .font(.subheadline)
                                }
                            }
                        }

                        if medication.needsRefill {
                            Label("Running low - consider refilling soon", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal)
                }

                // Details
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Details")
                        .font(.headline)

                    VStack(spacing: Theme.Spacing.sm) {
                        DetailRow(label: "Started", value: medication.startDate.formatted(date: .long, time: .omitted))

                        if let endDate = medication.endDate {
                            DetailRow(label: "End Date", value: endDate.formatted(date: .long, time: .omitted))
                        }

                        DetailRow(label: "Added", value: medication.createdAt.formatted(date: .long, time: .shortened))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .padding(.horizontal)

                // Action Buttons
                VStack(spacing: Theme.Spacing.md) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Label("Log Dose", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.module(medication.colorName))

                    Button {
                        medication.isActive.toggle()
                    } label: {
                        Label(
                            medication.isActive ? "Mark as Inactive" : "Mark as Active",
                            systemImage: medication.isActive ? "pause.circle" : "play.circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Medication")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        Task {
                            await NotificationService.shared.scheduleMedicationReminders(for: medication)
                        }
                    } label: {
                        Label("Update Reminders", systemImage: "bell.badge")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditMedicationView(medication: medication)
        }
        .sheet(isPresented: $showingLogSheet) {
            LogDoseSheet(medication: medication)
        }
        .alert("Delete Medication", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteMedication()
            }
        } message: {
            Text("Are you sure you want to delete this medication and all its logs?")
        }
    }

    private func deleteMedication() {
        Task {
            await NotificationService.shared.cancelMedicationReminders(for: medication.id)
        }
        modelContext.delete(medication)
        dismiss()
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct LogRow: View {
    let log: MedicationLog

    var body: some View {
        HStack {
            Image(systemName: log.status.icon)
                .foregroundStyle(Color.module(log.status.color))

            VStack(alignment: .leading) {
                Text(log.scheduledTime, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let actual = log.actualTime {
                    Text("Taken at \(actual, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(log.status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct EditMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var medication: Medication

    @State private var name: String
    @State private var dosage: String
    @State private var dosageUnit: DosageUnit
    @State private var frequency: MedicationFrequency
    @State private var times: [Date]
    @State private var instructions: String
    @State private var remainingCount: String
    @State private var refillReminderDays: String
    @State private var isActive: Bool
    @State private var selectedColor: String

    private let colors = ["blue", "green", "red", "purple", "orange", "pink", "mint", "indigo"]

    init(medication: Medication) {
        self.medication = medication
        _name = State(initialValue: medication.name)
        _dosage = State(initialValue: medication.dosage)
        _dosageUnit = State(initialValue: medication.dosageUnit)
        _frequency = State(initialValue: medication.frequency)
        _times = State(initialValue: medication.times)
        _instructions = State(initialValue: medication.instructions ?? "")
        _remainingCount = State(initialValue: medication.remainingCount.map { String($0) } ?? "")
        _refillReminderDays = State(initialValue: medication.refillReminderDays.map { String($0) } ?? "")
        _isActive = State(initialValue: medication.isActive)
        _selectedColor = State(initialValue: medication.colorName)
    }

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

                    Toggle("Active", isOn: $isActive)
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
                    .onDelete { offsets in
                        times.remove(atOffsets: offsets)
                    }

                    Button("Add Time") {
                        times.append(Date())
                    }
                }

                Section("Inventory") {
                    TextField("Remaining Count", text: $remainingCount)
                        .keyboardType(.numberPad)
                    TextField("Refill Reminder (days)", text: $refillReminderDays)
                        .keyboardType(.numberPad)
                }

                Section("Additional Info") {
                    TextField("Instructions", text: $instructions, axis: .vertical)
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
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        medication.name = name
        medication.dosage = dosage
        medication.dosageUnit = dosageUnit
        medication.frequency = frequency
        medication.times = times
        medication.instructions = instructions.isEmpty ? nil : instructions
        medication.remainingCount = Int(remainingCount)
        medication.refillReminderDays = Int(refillReminderDays)
        medication.isActive = isActive
        medication.colorName = selectedColor

        // Update notifications
        Task {
            await NotificationService.shared.scheduleMedicationReminders(for: medication)
        }

        dismiss()
    }
}

struct LogDoseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let medication: Medication

    @State private var status: MedicationLogStatus = .taken
    @State private var time = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Dose Status") {
                    Picker("Status", selection: $status) {
                        ForEach([MedicationLogStatus.taken, .skipped], id: \.self) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Time") {
                    DatePicker("Time", selection: $time, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDose() }
                }
            }
        }
    }

    private func saveDose() {
        let log = MedicationLog(
            scheduledTime: time,
            actualTime: status == .taken ? time : nil,
            status: status,
            notes: notes.isEmpty ? nil : notes,
            medication: medication
        )
        modelContext.insert(log)

        // Update remaining count if taken
        if status == .taken, let remaining = medication.remainingCount {
            medication.remainingCount = max(0, remaining - 1)
        }

        dismiss()
    }
}
