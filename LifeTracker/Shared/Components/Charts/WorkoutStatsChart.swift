import SwiftUI
import Charts

struct WorkoutDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let workoutType: WorkoutType
    let duration: TimeInterval
    let volume: Double
    let sets: Int
}

struct WeeklyWorkoutSummary: Identifiable {
    let id = UUID()
    let weekStart: Date
    let workoutCount: Int
    let totalDuration: TimeInterval
    let totalVolume: Double
}

struct WorkoutStatsChart: View {
    let dataPoints: [WorkoutDataPoint]
    @State private var selectedMetric: WorkoutMetric = .frequency

    enum WorkoutMetric: String, CaseIterable {
        case frequency = "Workouts"
        case duration = "Duration"
        case volume = "Volume"

        var icon: String {
            switch self {
            case .frequency: return "figure.run"
            case .duration: return "clock"
            case .volume: return "scalemass"
            }
        }
    }

    private var weeklyData: [WeeklyWorkoutSummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dataPoints) { point in
            calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
        }

        return grouped.map { (weekStart, points) in
            WeeklyWorkoutSummary(
                weekStart: weekStart,
                workoutCount: points.count,
                totalDuration: points.reduce(0) { $0 + $1.duration },
                totalVolume: points.reduce(0) { $0 + $1.volume }
            )
        }.sorted { $0.weekStart < $1.weekStart }
    }

    private var workoutsByType: [(type: WorkoutType, count: Int)] {
        let grouped = Dictionary(grouping: dataPoints) { $0.workoutType }
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var thisWeekWorkouts: Int {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return dataPoints.filter { $0.date >= weekStart }.count
    }

    private var totalWorkouts: Int {
        dataPoints.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView

            if dataPoints.isEmpty {
                emptyStateView
            } else {
                metricPicker

                switch selectedMetric {
                case .frequency:
                    frequencyChart
                case .duration:
                    durationChart
                case .volume:
                    volumeChart
                }

                workoutTypeBreakdown
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout Statistics")
                    .font(.headline)
                Text("\(thisWeekWorkouts) workouts this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalWorkouts)")
                    .font(.title2.bold())
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No workout data yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Log workouts to see your statistics")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var metricPicker: some View {
        HStack(spacing: 8) {
            ForEach(WorkoutMetric.allCases, id: \.self) { metric in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMetric = metric
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: metric.icon)
                        Text(metric.rawValue)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedMetric == metric ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundStyle(selectedMetric == metric ? .white : .primary)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var frequencyChart: some View {
        Chart(weeklyData) { week in
            BarMark(
                x: .value("Week", week.weekStart, unit: .weekOfYear),
                y: .value("Workouts", week.workoutCount)
            )
            .foregroundStyle(Color.blue.gradient)
            .cornerRadius(4)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
    }

    private var durationChart: some View {
        Chart(weeklyData) { week in
            BarMark(
                x: .value("Week", week.weekStart, unit: .weekOfYear),
                y: .value("Hours", week.totalDuration / 3600)
            )
            .foregroundStyle(Color.orange.gradient)
            .cornerRadius(4)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text(String(format: "%.1fh", hours))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }

    private var volumeChart: some View {
        Chart(weeklyData) { week in
            BarMark(
                x: .value("Week", week.weekStart, unit: .weekOfYear),
                y: .value("Volume", week.totalVolume / 1000)
            )
            .foregroundStyle(Color.green.gradient)
            .cornerRadius(4)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let vol = value.as(Double.self) {
                        Text(String(format: "%.0fk", vol))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }

    private var workoutTypeBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Type")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 8) {
                ForEach(workoutsByType.prefix(4), id: \.type) { item in
                    HStack(spacing: 4) {
                        Image(systemName: item.type.icon)
                            .font(.caption2)
                        Text("\(item.count)")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(item.type.color).opacity(0.15))
                    .foregroundStyle(Color(item.type.color))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

// Extension to get Color from string
extension Color {
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "red": self = .red
        case "green": self = .green
        case "blue": self = .blue
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink": self = .pink
        case "yellow": self = .yellow
        case "gray", "grey": self = .gray
        default: self = .primary
        }
    }
}

#Preview {
    let types: [WorkoutType] = [.strength, .cardio, .hiit, .flexibility]
    var sampleData: [WorkoutDataPoint] = []

    for i in 0..<30 {
        if Bool.random() && Bool.random() {
            let date = Calendar.current.date(byAdding: .day, value: -29 + i, to: Date())!
            sampleData.append(WorkoutDataPoint(
                date: date,
                workoutType: types.randomElement()!,
                duration: Double.random(in: 1800...5400),
                volume: Double.random(in: 5000...20000),
                sets: Int.random(in: 12...30)
            ))
        }
    }

    return ScrollView {
        VStack(spacing: 20) {
            WorkoutStatsChart(dataPoints: sampleData)
            WorkoutStatsChart(dataPoints: [])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
