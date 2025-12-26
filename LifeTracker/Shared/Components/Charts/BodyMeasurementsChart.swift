import SwiftUI
import Charts

struct MeasurementDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let measurement: String
    let value: Double
    let unit: MeasurementUnit
}

struct BodyMeasurementsChart: View {
    let dataPoints: [MeasurementDataPoint]
    let selectedMeasurements: Set<String>

    @State private var selectedPoint: MeasurementDataPoint?

    private let measurementColors: [String: Color] = [
        "Chest": .blue,
        "Waist": .orange,
        "Hips": .purple,
        "Left Bicep": .green,
        "Right Bicep": .teal,
        "Left Thigh": .pink,
        "Right Thigh": .red,
        "Neck": .indigo,
        "Shoulders": .cyan
    ]

    init(dataPoints: [MeasurementDataPoint], selectedMeasurements: Set<String>? = nil) {
        self.dataPoints = dataPoints.sorted { $0.date < $1.date }
        self.selectedMeasurements = selectedMeasurements ?? Set(dataPoints.map { $0.measurement })
    }

    private var filteredDataPoints: [MeasurementDataPoint] {
        dataPoints.filter { selectedMeasurements.contains($0.measurement) }
    }

    private var availableMeasurements: [String] {
        Array(Set(dataPoints.map { $0.measurement })).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if filteredDataPoints.isEmpty {
                emptyStateView
            } else {
                chartView
                    .frame(height: 220)

                legendView
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
                Text("Body Measurements")
                    .font(.headline)
                Text("Track your progress over time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "ruler")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.stand")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No measurements yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Add body measurements to track changes")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        Chart {
            ForEach(filteredDataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value),
                    series: .value("Measurement", point.measurement)
                )
                .foregroundStyle(by: .value("Measurement", point.measurement))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Measurement", point.measurement))
                .symbolSize(30)
            }
        }
        .chartForegroundStyleScale(mapping: { (measurement: String) in
            measurementColors[measurement] ?? .gray
        })
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
                    if let val = value.as(Double.self) {
                        Text(String(format: "%.0f", val))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartLegend(.hidden)
    }

    private var legendView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableMeasurements, id: \.self) { measurement in
                    if selectedMeasurements.contains(measurement) {
                        legendItem(for: measurement)
                    }
                }
            }
        }
    }

    private func legendItem(for measurement: String) -> some View {
        let latestValue = dataPoints
            .filter { $0.measurement == measurement }
            .sorted { $0.date > $1.date }
            .first

        return HStack(spacing: 6) {
            Circle()
                .fill(measurementColors[measurement] ?? .gray)
                .frame(width: 8, height: 8)
            Text(measurement)
                .font(.caption)
            if let value = latestValue {
                Text(String(format: "%.1f", value.value))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

#Preview {
    let measurements = ["Chest", "Waist", "Hips", "Left Bicep", "Right Bicep"]
    var sampleData: [MeasurementDataPoint] = []

    for i in 0..<15 {
        let date = Calendar.current.date(byAdding: .day, value: -14 + i, to: Date())!
        for measurement in measurements {
            let baseValue: Double = {
                switch measurement {
                case "Chest": return 100
                case "Waist": return 85
                case "Hips": return 95
                case "Left Bicep", "Right Bicep": return 35
                default: return 50
                }
            }()

            sampleData.append(MeasurementDataPoint(
                date: date,
                measurement: measurement,
                value: baseValue + Double(i) * 0.2 + Double.random(in: -0.5...0.5),
                unit: .cm
            ))
        }
    }

    return ScrollView {
        VStack(spacing: 20) {
            BodyMeasurementsChart(
                dataPoints: sampleData,
                selectedMeasurements: Set(["Chest", "Waist", "Hips"])
            )
            BodyMeasurementsChart(dataPoints: [])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
