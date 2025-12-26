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
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    @State private var selectedTimeRange: TimeRange = .month

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }

    private var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
    }

    private var filteredMeasurements: [BodyMeasurement] {
        measurements.filter { $0.date >= startDate }
    }

    private var filteredWorkouts: [Workout] {
        workouts.filter { $0.date >= startDate }
    }

    private var weightDataPoints: [WeightDataPoint] {
        filteredMeasurements.compactMap { measurement in
            guard let weight = measurement.weight else { return nil }
            return WeightDataPoint(
                date: measurement.date,
                weight: weight,
                unit: measurement.weightUnit
            )
        }
    }

    private var bodyFatDataPoints: [BodyFatDataPoint] {
        filteredMeasurements.compactMap { measurement in
            guard let bodyFat = measurement.bodyFatPercentage else { return nil }
            return BodyFatDataPoint(date: measurement.date, percentage: bodyFat)
        }
    }

    private var measurementDataPoints: [MeasurementDataPoint] {
        var points: [MeasurementDataPoint] = []

        for measurement in filteredMeasurements {
            let summary = measurement.measurementsSummary
            for (name, value) in summary {
                points.append(MeasurementDataPoint(
                    date: measurement.date,
                    measurement: name,
                    value: value,
                    unit: measurement.measurementUnit
                ))
            }
        }

        return points
    }

    private var workoutDataPoints: [WorkoutDataPoint] {
        filteredWorkouts.map { workout in
            WorkoutDataPoint(
                date: workout.date,
                workoutType: workout.type,
                duration: workout.duration,
                volume: workout.totalVolume,
                sets: workout.totalSets
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                timeRangePicker

                if measurements.isEmpty && workouts.isEmpty {
                    emptyStateView
                } else {
                    chartsContent
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTimeRange = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTimeRange == range ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedTimeRange == range ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Progress Data Yet")
                .font(.title2.weight(.semibold))

            Text("Start logging workouts and measurements\nto see your progress charts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    private var chartsContent: some View {
        if !weightDataPoints.isEmpty {
            WeightProgressChart(
                dataPoints: weightDataPoints,
                showGoal: true,
                goalWeight: 75
            )
        }

        if !bodyFatDataPoints.isEmpty {
            BodyFatChart(dataPoints: bodyFatDataPoints)
        }

        if !measurementDataPoints.isEmpty {
            BodyMeasurementsChart(
                dataPoints: measurementDataPoints,
                selectedMeasurements: Set(["Chest", "Waist", "Hips"])
            )
        }

        if !workoutDataPoints.isEmpty {
            WorkoutStatsChart(dataPoints: workoutDataPoints)
        }

        if !measurements.isEmpty || !workouts.isEmpty {
            summaryStatsView
        }
    }

    private var summaryStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let firstWeight = weightDataPoints.first?.weight,
                   let lastWeight = weightDataPoints.last?.weight {
                    summaryCard(
                        title: "Weight Change",
                        value: String(format: "%+.1f kg", lastWeight - firstWeight),
                        icon: "scalemass",
                        color: lastWeight <= firstWeight ? .green : .red
                    )
                }

                summaryCard(
                    title: "Workouts",
                    value: "\(filteredWorkouts.count)",
                    icon: "figure.run",
                    color: .blue
                )

                summaryCard(
                    title: "Total Duration",
                    value: formatDuration(filteredWorkouts.reduce(0) { $0 + $1.duration }),
                    icon: "clock",
                    color: .orange
                )

                summaryCard(
                    title: "Measurements",
                    value: "\(filteredMeasurements.count)",
                    icon: "ruler",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
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
