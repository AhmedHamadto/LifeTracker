import SwiftUI
import SwiftData

struct ProgressChartsView: View {
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
            VStack(spacing: 16) {
                timeRangePicker

                if measurements.isEmpty && workouts.isEmpty {
                    emptyStateView
                } else {
                    chartsContent
                }
            }
            .padding()
        }
        .navigationTitle("Progress")
        .background(Color(.systemGroupedBackground))
    }

    private var timeRangePicker: some View {
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
                goalWeight: 75 // This could come from user settings
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

        // Summary stats
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

#Preview {
    NavigationStack {
        ProgressChartsView()
    }
    .modelContainer(for: [BodyMeasurement.self, Workout.self], inMemory: true)
}
