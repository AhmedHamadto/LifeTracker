import SwiftUI
import Charts

struct BodyFatDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let percentage: Double
}

struct BodyFatChart: View {
    let dataPoints: [BodyFatDataPoint]
    let showCategories: Bool

    @State private var selectedPoint: BodyFatDataPoint?

    init(dataPoints: [BodyFatDataPoint], showCategories: Bool = true) {
        self.dataPoints = dataPoints.sorted { $0.date < $1.date }
        self.showCategories = showCategories
    }

    private var latestPercentage: Double? {
        dataPoints.last?.percentage
    }

    private var change: Double? {
        guard dataPoints.count >= 2 else { return nil }
        return dataPoints.last!.percentage - dataPoints.first!.percentage
    }

    private var category: (name: String, color: Color) {
        guard let latest = latestPercentage else { return ("Unknown", .gray) }

        switch latest {
        case 0..<6: return ("Essential", .red)
        case 6..<14: return ("Athletic", .green)
        case 14..<18: return ("Fitness", .blue)
        case 18..<25: return ("Average", .orange)
        default: return ("Above Average", .red)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if dataPoints.isEmpty {
                emptyStateView
            } else {
                chartView
                    .frame(height: 160)

                if showCategories {
                    categoryIndicator
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
                Text("Body Fat %")
                    .font(.headline)

                if let change = change {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(change >= 0 ? .red : .green)
                        Text(String(format: "%+.1f%%", change))
                            .foregroundStyle(change >= 0 ? .red : .green)
                    }
                    .font(.subheadline)
                }
            }

            Spacer()

            if let latest = latestPercentage {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f%%", latest))
                        .font(.title2.bold())
                    Text(category.name)
                        .font(.caption)
                        .foregroundStyle(category.color)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "percent")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No body fat data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        Chart {
            // Category zones (background)
            if showCategories {
                RectangleMark(
                    xStart: nil,
                    xEnd: nil,
                    yStart: .value("Min", 6),
                    yEnd: .value("Max", 14)
                )
                .foregroundStyle(.green.opacity(0.1))

                RectangleMark(
                    xStart: nil,
                    xEnd: nil,
                    yStart: .value("Min", 14),
                    yEnd: .value("Max", 18)
                )
                .foregroundStyle(.blue.opacity(0.1))

                RectangleMark(
                    xStart: nil,
                    xEnd: nil,
                    yStart: .value("Min", 18),
                    yEnd: .value("Max", 25)
                )
                .foregroundStyle(.orange.opacity(0.1))
            }

            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Body Fat", point.percentage)
                )
                .foregroundStyle(Color.purple.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Body Fat", point.percentage)
                )
                .foregroundStyle(.purple)
                .symbolSize(40)
            }
        }
        .chartYScale(domain: 0...35)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 10, 20, 30]) { value in
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text("\(Int(pct))%")
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }

    private var categoryIndicator: some View {
        HStack(spacing: 12) {
            ForEach([
                ("Athletic", Color.green, "6-14%"),
                ("Fitness", Color.blue, "14-18%"),
                ("Average", Color.orange, "18-25%")
            ], id: \.0) { name, color, range in
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.caption2)
                    Text(range)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    let sampleData = (0..<20).map { i in
        BodyFatDataPoint(
            date: Calendar.current.date(byAdding: .day, value: -19 + i, to: Date())!,
            percentage: 18 - Double(i) * 0.1 + Double.random(in: -0.3...0.3)
        )
    }

    return ScrollView {
        VStack(spacing: 20) {
            BodyFatChart(dataPoints: sampleData)
            BodyFatChart(dataPoints: [], showCategories: false)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
