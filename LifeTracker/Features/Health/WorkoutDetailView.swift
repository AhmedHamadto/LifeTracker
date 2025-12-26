import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var workout: Workout

    @State private var isEditing = false
    @State private var showingAddExercise = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                VStack(spacing: Theme.Spacing.lg) {
                    Circle()
                        .fill(Color.module(workout.type.color))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: workout.type.icon)
                                .font(.system(size: 35))
                                .foregroundStyle(.white)
                        }

                    VStack(spacing: Theme.Spacing.xs) {
                        Text(workout.displayName)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(workout.date.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Stats
                    HStack(spacing: Theme.Spacing.xl) {
                        WorkoutStatItem(value: workout.durationDisplay, label: "Duration")
                        WorkoutStatItem(value: "\(workout.exercises.count)", label: "Exercises")
                        WorkoutStatItem(value: "\(workout.totalSets)", label: "Sets")
                        if workout.caloriesBurned != nil {
                            WorkoutStatItem(value: "\(workout.caloriesBurned!)", label: "Calories")
                        }
                    }

                    // Rating
                    if let rating = workout.rating {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .foregroundStyle(i <= rating ? .yellow : .secondary)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .padding(.horizontal)

                // Exercises
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Text("Exercises")
                            .font(.headline)

                        Spacer()

                        Button {
                            showingAddExercise = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }

                    if workout.exercises.isEmpty {
                        Text("No exercises logged")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { exercise in
                            ExerciseCard(exercise: exercise)
                        }
                    }
                }
                .padding(.horizontal)

                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Notes")
                            .font(.headline)

                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                    .padding(.horizontal)
                }

                // Summary
                if !workout.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Summary")
                            .font(.headline)

                        VStack(spacing: Theme.Spacing.sm) {
                            DetailRow(label: "Total Volume", value: "\(Int(workout.totalVolume)) kg")
                            DetailRow(label: "Muscle Groups", value: muscleGroupsSummary)
                        }
                        .padding()
                        .background(Theme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                    .padding(.horizontal)
                }

                // Actions
                Button {
                    Task {
                        try? await HealthKitService.shared.saveWorkout(workout)
                    }
                } label: {
                    Label("Sync to Apple Health", systemImage: "heart.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
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
            EditWorkoutView(workout: workout)
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(workout: workout)
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete this workout?")
        }
    }

    private var muscleGroupsSummary: String {
        let groups = Set(workout.exercises.map { $0.muscleGroup.rawValue })
        return groups.joined(separator: ", ")
    }

    private func deleteWorkout() {
        modelContext.delete(workout)
        dismiss()
    }
}

struct WorkoutStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(exercise.muscleGroup.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(exercise.sets.count) sets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded && !exercise.sets.isEmpty {
                VStack(spacing: Theme.Spacing.xs) {
                    // Header
                    HStack {
                        Text("Set")
                            .frame(width: 40, alignment: .leading)
                        Text("Weight")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Reps")
                            .frame(width: 60, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    ForEach(exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                        HStack {
                            HStack(spacing: 4) {
                                Text("\(set.setNumber)")
                                    .frame(width: 40, alignment: .leading)
                                if set.isWarmup {
                                    Text("W")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }

                            HStack(spacing: 4) {
                                Text(set.displayWeight)
                                if set.isPersonalRecord {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(set.reps)")
                                .frame(width: 60, alignment: .trailing)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding()
        .background(Theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

struct EditWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var workout: Workout

    @State private var type: WorkoutType
    @State private var name: String
    @State private var date: Date
    @State private var duration: TimeInterval
    @State private var caloriesBurned: String
    @State private var rating: Int
    @State private var notes: String

    init(workout: Workout) {
        self.workout = workout
        _type = State(initialValue: workout.type)
        _name = State(initialValue: workout.name ?? "")
        _date = State(initialValue: workout.date)
        _duration = State(initialValue: workout.duration)
        _caloriesBurned = State(initialValue: workout.caloriesBurned.map { String($0) } ?? "")
        _rating = State(initialValue: workout.rating ?? 0)
        _notes = State(initialValue: workout.notes ?? "")
    }

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

                Section("Duration & Calories") {
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

                    TextField("Calories Burned", text: $caloriesBurned)
                        .keyboardType(.numberPad)
                }

                Section("Rating") {
                    HStack {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                rating = i
                            } label: {
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(i <= rating ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        if rating > 0 {
                            Button("Clear") {
                                rating = 0
                            }
                            .font(.caption)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
        }
    }

    private func saveChanges() {
        workout.type = type
        workout.name = name.isEmpty ? nil : name
        workout.date = date
        workout.duration = duration
        workout.caloriesBurned = Int(caloriesBurned)
        workout.rating = rating > 0 ? rating : nil
        workout.notes = notes.isEmpty ? nil : notes

        dismiss()
    }
}

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let workout: Workout

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var sets: [SetInput] = [SetInput()]

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise Name", text: $name)

                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                }

                Section("Sets") {
                    ForEach(sets.indices, id: \.self) { index in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.subheadline)
                                .frame(width: 50)

                            TextField("Weight", text: $sets[index].weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)

                            Text("kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField("Reps", text: $sets[index].reps)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)

                            Button {
                                sets.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .disabled(sets.count == 1)
                        }
                    }

                    Button("Add Set") {
                        sets.append(SetInput())
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveExercise() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveExercise() {
        let exercise = Exercise(
            name: name,
            muscleGroup: muscleGroup,
            order: workout.exercises.count,
            workout: workout
        )
        modelContext.insert(exercise)

        for (index, setInput) in sets.enumerated() {
            if let weight = Double(setInput.weight), let reps = Int(setInput.reps) {
                let set = ExerciseSet(
                    setNumber: index + 1,
                    weight: weight,
                    reps: reps,
                    exercise: exercise
                )
                modelContext.insert(set)
            }
        }

        dismiss()
    }
}

struct SetInput {
    var weight = ""
    var reps = ""
}
