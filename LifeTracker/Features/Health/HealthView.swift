import SwiftUI
import SwiftData

struct HealthView: View {
    @State private var selectedTab: HealthTab = .workouts

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Section", selection: $selectedTab) {
                    ForEach(HealthTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    WorkoutsListView()
                        .tag(HealthTab.workouts)

                    MeasurementsListView()
                        .tag(HealthTab.measurements)

                    ProgressView()
                        .tag(HealthTab.progress)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Health & Fitness")
        }
    }
}

enum HealthTab: String, CaseIterable, Identifiable {
    case workouts = "Workouts"
    case measurements = "Measurements"
    case progress = "Progress"

    var id: String { rawValue }
}

// MARK: - Workouts List

struct WorkoutsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    @State private var showingAddWorkout = false

    var body: some View {
        Group {
            if workouts.isEmpty {
                EmptyStateView(
                    icon: "dumbbell.fill",
                    title: "No Workouts",
                    message: "Start logging your workouts to track progress",
                    buttonTitle: "Log Workout"
                ) {
                    showingAddWorkout = true
                }
            } else {
                workoutsList
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddWorkout = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutView()
        }
    }

    private var workoutsList: some View {
        List {
            // This Week Summary
            Section {
                HStack(spacing: Theme.Spacing.xl) {
                    VStack {
                        Text("\(thisWeekWorkouts.count)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Workouts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    VStack {
                        Text(thisWeekDuration)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    VStack {
                        Text("\(thisWeekExercises)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
            } header: {
                Text("This Week")
            }

            // Workouts
            ForEach(workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutRowView(workout: workout)
                }
            }
            .onDelete(perform: deleteWorkouts)
        }
        .listStyle(.insetGrouped)
    }

    private var thisWeekWorkouts: [Workout] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return workouts.filter { $0.date >= startOfWeek }
    }

    private var thisWeekDuration: String {
        let total = thisWeekWorkouts.reduce(0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var thisWeekExercises: Int {
        thisWeekWorkouts.reduce(0) { $0 + $1.exercises.count }
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(workouts[index])
        }
    }
}

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Color.module(workout.type.color))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: workout.type.icon)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(workout.displayName)
                    .font(.headline)

                HStack {
                    Text("\(workout.exercises.count) exercises")
                    Text("•")
                    Text(workout.durationDisplay)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let rating = workout.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(i <= rating ? .yellow : .secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Measurements List

struct MeasurementsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]

    @State private var showingAddMeasurement = false

    var body: some View {
        Group {
            if measurements.isEmpty {
                EmptyStateView(
                    icon: "ruler",
                    title: "No Measurements",
                    message: "Track your body measurements to see progress over time",
                    buttonTitle: "Add Measurement"
                ) {
                    showingAddMeasurement = true
                }
            } else {
                measurementsList
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddMeasurement = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView()
        }
    }

    private var measurementsList: some View {
        List {
            ForEach(measurements) { measurement in
                NavigationLink(destination: MeasurementDetailView(measurement: measurement)) {
                    MeasurementRowView(measurement: measurement)
                }
            }
            .onDelete(perform: deleteMeasurements)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteMeasurements(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(measurements[index])
        }
    }
}

struct MeasurementRowView: View {
    let measurement: BodyMeasurement

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(measurement.date, style: .date)
                    .font(.headline)

                Spacer()

                if measurement.photo != nil {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: Theme.Spacing.lg) {
                if let weight = measurement.displayWeight {
                    VStack(alignment: .leading) {
                        Text("Weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(weight)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                if let bf = measurement.displayBodyFat {
                    VStack(alignment: .leading) {
                        Text("Body Fat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(bf)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }

            if !measurement.measurementsSummary.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(Array(measurement.measurementsSummary.keys.sorted()), id: \.self) { key in
                            if let value = measurement.measurementsSummary[key] {
                                VStack {
                                    Text(key)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(Int(value)) \(measurement.measurementUnit.rawValue)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Progress View

struct ProgressView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Placeholder for charts
                CardView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Weight Progress")
                            .font(.headline)

                        Text("Connect to Apple Health to see your weight trend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Connect Health") {}
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Workout Frequency")
                            .font(.headline)

                        Text("Start logging workouts to see your activity trend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Personal Records")
                            .font(.headline)

                        Text("Your PRs will appear here as you log workouts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}

// MARK: - Add Workout View

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var type: WorkoutType = .strength
    @State private var name = ""
    @State private var date = Date()
    @State private var duration: TimeInterval = 3600
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    Picker("Type", selection: $type) {
                        ForEach(WorkoutType.allCases) { workoutType in
                            Label(workoutType.rawValue, systemImage: workoutType.icon)
                                .tag(workoutType)
                        }
                    }

                    TextField("Name (optional)", text: $name)

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Duration") {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Stepper(
                            "\(Int(duration / 60)) min",
                            value: $duration,
                            in: 300...14400,
                            step: 300
                        )
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWorkout() }
                }
            }
        }
    }

    private func saveWorkout() {
        let workout = Workout(
            date: date,
            type: type,
            name: name.isEmpty ? nil : name,
            duration: duration,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(workout)
        dismiss()
    }
}

#Preview {
    HealthView()
        .modelContainer(for: [Workout.self, BodyMeasurement.self], inMemory: true)
}
