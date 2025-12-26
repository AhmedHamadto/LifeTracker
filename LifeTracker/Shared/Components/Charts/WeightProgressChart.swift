import SwiftUI
import Charts

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let unit: WeightUnit

    var displayWeight: String {
        String(format: "%.1f %@", weight, unit.rawValue)
    }
}

struct WeightProgressChart: View {
    let dataPoints: [WeightDataPoint]
    let showGoal: Bool
    let goalWeight: Double?

    @State private var selectedPoint: WeightDataPoint?

    init(dataPoints: [WeightDataPoint], showGoal: Bool = false, goalWeight: Double? = nil) {
        self.dataPoints = dataPoints.sorted { $0.date < $1.date }
        self.showGoal = showGoal
        self.goalWeight = goalWeight
    }

    private var minWeight: Double {
        let weights = dataPoints.map { $0.weight }
        let min = weights.min() ?? 0
        return max(0, min - 5)
    }

    private var maxWeight: Double {
        let weights = dataPoints.map { $0.weight }
        let max = weights.max() ?? 100
        return max + 5
    }

    private var weightChange: Double? {
        guard dataPoints.count >= 2 else { return nil }
        return dataPoints.last!.weight - dataPoints.first!.weight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if dataPoints.isEmpty {
                emptyStateView
            } else {
                chartView
                    .frame(height: 200)

                if let selected = selectedPoint {
                    selectedPointView(selected)
                }
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
                Text("Weight Progress")
                    .font(.headline)

                if let change = weightChange {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(change >= 0 ? .red : .green)
                        Text(String(format: "%+.1f", change))
                            .foregroundStyle(change >= 0 ? .red : .green)
                        Text(dataPoints.first?.unit.rawValue ?? "kg")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }

            Spacer()

            if let latest = dataPoints.last {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(latest.displayWeight)
                        .font(.title2.bold())
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No weight data yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Add measurements to see your progress")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(selectedPoint?.id == point.id ? 100 : 40)
            }

            if showGoal, let goal = goalWeight {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(.green.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal: \(String(format: "%.1f", goal))")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
            }
        }
        .chartYScale(domain: minWeight...maxWeight)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text(String(format: "%.0f", weight))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = value.location.x - geometry[plotFrame].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedPoint = dataPoints.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                }
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
    }

    private func selectedPointView(_ point: WeightDataPoint) -> some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
            Text(point.date, format: .dateTime.month(.abbreviated).day().year())
            Spacer()
            Text(point.displayWeight)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let sampleData = (0..<30).map { i in
        WeightDataPoint(
            date: Calendar.current.date(byAdding: .day, value: -29 + i, to: Date())!,
            weight: 80 - Double(i) * 0.15 + Double.random(in: -0.5...0.5),
            unit: .kg
        )
    }

    return ScrollView {
        VStack(spacing: 20) {
            WeightProgressChart(dataPoints: sampleData, showGoal: true, goalWeight: 75)
            WeightProgressChart(dataPoints: [])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
