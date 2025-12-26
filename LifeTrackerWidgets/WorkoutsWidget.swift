import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let weeklyWorkouts: Int
    let weeklyDuration: TimeInterval
    let weeklyGoal: Int
    let recentWorkouts: [WorkoutWidgetData]
    let streak: Int
}

struct WorkoutWidgetData: Identifiable {
    let id: UUID
    let name: String
    let type: String
    let date: Date
    let duration: TimeInterval
    let exerciseCount: Int
    let colorName: String
    let icon: String
}

// MARK: - Timeline Provider

struct WorkoutsProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutEntry {
        WorkoutEntry(
            date: Date(),
            weeklyWorkouts: 4,
            weeklyDuration: 14400,
            weeklyGoal: 5,
            recentWorkouts: [
                WorkoutWidgetData(id: UUID(), name: "Push Day", type: "Strength", date: Date(), duration: 3600, exerciseCount: 6, colorName: "red", icon: "dumbbell.fill"),
                WorkoutWidgetData(id: UUID(), name: "Morning Run", type: "Cardio", date: Date().addingTimeInterval(-86400), duration: 2400, exerciseCount: 1, colorName: "green", icon: "figure.run")
            ],
            streak: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutEntry>) -> Void) {
        let entry = WorkoutEntry(
            date: Date(),
            weeklyWorkouts: loadWeeklyWorkoutCount(),
            weeklyDuration: loadWeeklyDuration(),
            weeklyGoal: 5,
            recentWorkouts: loadRecentWorkouts(),
            streak: loadStreak()
        )

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadWeeklyWorkoutCount() -> Int {
        // TODO: Load from App Group shared container
        return 4
    }

    private func loadWeeklyDuration() -> TimeInterval {
        return 14400 // 4 hours
    }

    private func loadRecentWorkouts() -> [WorkoutWidgetData] {
        return [
            WorkoutWidgetData(id: UUID(), name: "Push Day", type: "Strength", date: Date(), duration: 3600, exerciseCount: 6, colorName: "red", icon: "dumbbell.fill"),
            WorkoutWidgetData(id: UUID(), name: "Morning Run", type: "Cardio", date: Date().addingTimeInterval(-86400), duration: 2400, exerciseCount: 1, colorName: "green", icon: "figure.run"),
            WorkoutWidgetData(id: UUID(), name: "Pull Day", type: "Strength", date: Date().addingTimeInterval(-172800), duration: 4200, exerciseCount: 7, colorName: "red", icon: "dumbbell.fill")
        ]
    }

    private func loadStreak() -> Int {
        return 3
    }
}

// MARK: - Widget Views

struct WorkoutsWidgetEntryView: View {
    var entry: WorkoutsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWorkoutView(entry: entry)
        case .systemMedium:
            MediumWorkoutView(entry: entry)
        case .systemLarge:
            LargeWorkoutView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularWorkoutView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularWorkoutView(entry: entry)
        default:
            SmallWorkoutView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWorkoutView: View {
    let entry: WorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                Spacer()
                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame")
                            .font(.caption2)
                        Text("\(entry.streak)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.orange)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("This Week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(entry.weeklyWorkouts)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.primary)

                Text("workouts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress to goal
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.secondary.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(.red)
                        .frame(width: geometry.size.width * progressValue, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var progressValue: Double {
        min(1.0, Double(entry.weeklyWorkouts) / Double(entry.weeklyGoal))
    }
}

// MARK: - Medium Widget

struct MediumWorkoutView: View {
    let entry: WorkoutEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Weekly stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                    Text("Workouts")
                        .font(.headline)
                }

                Spacer()

                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("\(entry.weeklyWorkouts)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("this week")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text(durationString)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("total time")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Weekly goal progress
                HStack {
                    Text("Goal: \(entry.weeklyWorkouts)/\(entry.weeklyGoal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if entry.streak > 0 {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("\(entry.streak) day streak")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right side - Recent workouts
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(entry.recentWorkouts.prefix(3)) { workout in
                    HStack(spacing: 8) {
                        Image(systemName: workout.icon)
                            .font(.caption)
                            .foregroundStyle(colorFor(workout.colorName))
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(workout.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(formatDuration(workout.duration))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var durationString: String {
        let hours = Int(entry.weeklyDuration) / 3600
        let minutes = (Int(entry.weeklyDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    private func colorFor(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        default: return .gray
        }
    }
}

// MARK: - Large Widget

struct LargeWorkoutView: View {
    let entry: WorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("Weekly Summary")
                    .font(.headline)

                Spacer()

                if entry.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(entry.streak) day streak")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2))
                    .clipShape(Capsule())
                }
            }

            // Stats row
            HStack(spacing: 20) {
                StatBox(value: "\(entry.weeklyWorkouts)", label: "Workouts", icon: "figure.run")
                StatBox(value: durationString, label: "Duration", icon: "clock.fill")
                StatBox(value: "\(totalExercises)", label: "Exercises", icon: "list.bullet")
            }

            // Goal progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Weekly Goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(entry.weeklyWorkouts) of \(entry.weeklyGoal)")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(entry.weeklyWorkouts >= entry.weeklyGoal ? .green : .red)
                            .frame(width: geometry.size.width * progressValue, height: 8)
                    }
                }
                .frame(height: 8)
            }

            Divider()

            // Recent workouts
            Text("Recent Workouts")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(entry.recentWorkouts) { workout in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(colorFor(workout.colorName))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: workout.icon)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(workout.exerciseCount) exercises • \(formatDuration(workout.duration))")
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

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var durationString: String {
        let hours = Int(entry.weeklyDuration) / 3600
        let minutes = (Int(entry.weeklyDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var totalExercises: Int {
        entry.recentWorkouts.reduce(0) { $0 + $1.exerciseCount }
    }

    private var progressValue: Double {
        min(1.0, Double(entry.weeklyWorkouts) / Double(entry.weeklyGoal))
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    private func colorFor(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        default: return .gray
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularWorkoutView: View {
    let entry: WorkoutEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                Text("\(entry.weeklyWorkouts)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
    }
}

struct AccessoryRectangularWorkoutView: View {
    let entry: WorkoutEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label("Workouts", systemImage: "flame.fill")
                    .font(.caption)

                Text("\(entry.weeklyWorkouts) this week")
                    .font(.headline)

                if entry.streak > 0 {
                    Text("\(entry.streak) day streak")
                        .font(.caption)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Widget Configuration

struct WorkoutsWidget: Widget {
    let kind: String = "WorkoutsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutsProvider()) { entry in
            WorkoutsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Workouts")
        .description("Track your weekly workout progress and stay motivated.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    WorkoutsWidget()
} timeline: {
    WorkoutEntry(
        date: Date(),
        weeklyWorkouts: 4,
        weeklyDuration: 14400,
        weeklyGoal: 5,
        recentWorkouts: [],
        streak: 3
    )
}

#Preview(as: .systemMedium) {
    WorkoutsWidget()
} timeline: {
    WorkoutEntry(
        date: Date(),
        weeklyWorkouts: 4,
        weeklyDuration: 14400,
        weeklyGoal: 5,
        recentWorkouts: [
            WorkoutWidgetData(id: UUID(), name: "Push Day", type: "Strength", date: Date(), duration: 3600, exerciseCount: 6, colorName: "red", icon: "dumbbell.fill"),
            WorkoutWidgetData(id: UUID(), name: "Morning Run", type: "Cardio", date: Date().addingTimeInterval(-86400), duration: 2400, exerciseCount: 1, colorName: "green", icon: "figure.run")
        ],
        streak: 3
    )
}

#Preview(as: .systemLarge) {
    WorkoutsWidget()
} timeline: {
    WorkoutEntry(
        date: Date(),
        weeklyWorkouts: 4,
        weeklyDuration: 14400,
        weeklyGoal: 5,
        recentWorkouts: [
            WorkoutWidgetData(id: UUID(), name: "Push Day", type: "Strength", date: Date(), duration: 3600, exerciseCount: 6, colorName: "red", icon: "dumbbell.fill"),
            WorkoutWidgetData(id: UUID(), name: "Morning Run", type: "Cardio", date: Date().addingTimeInterval(-86400), duration: 2400, exerciseCount: 1, colorName: "green", icon: "figure.run"),
            WorkoutWidgetData(id: UUID(), name: "Pull Day", type: "Strength", date: Date().addingTimeInterval(-172800), duration: 4200, exerciseCount: 7, colorName: "red", icon: "dumbbell.fill")
        ],
        streak: 3
    )
}
