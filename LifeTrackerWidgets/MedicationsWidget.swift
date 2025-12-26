import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MedicationEntry: TimelineEntry {
    let date: Date
    let medications: [MedicationWidgetData]
    let nextDose: MedicationWidgetData?
    let completedToday: Int
    let totalToday: Int
}

struct MedicationWidgetData: Identifiable {
    let id: UUID
    let name: String
    let dosage: String
    let nextDoseTime: Date?
    let colorName: String
    let isTaken: Bool
}

// MARK: - Timeline Provider

struct MedicationsProvider: TimelineProvider {
    func placeholder(in context: Context) -> MedicationEntry {
        MedicationEntry(
            date: Date(),
            medications: [
                MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date(), colorName: "orange", isTaken: false),
                MedicationWidgetData(id: UUID(), name: "Omega-3", dosage: "1000 mg", nextDoseTime: Date().addingTimeInterval(3600), colorName: "blue", isTaken: true)
            ],
            nextDose: MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date(), colorName: "orange", isTaken: false),
            completedToday: 2,
            totalToday: 4
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicationEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicationEntry>) -> Void) {
        // In a real app, fetch from shared App Group container or SwiftData
        let entry = MedicationEntry(
            date: Date(),
            medications: loadMedications(),
            nextDose: loadNextDose(),
            completedToday: 2,
            totalToday: 4
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadMedications() -> [MedicationWidgetData] {
        // TODO: Load from App Group shared container
        return [
            MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date().addingTimeInterval(1800), colorName: "orange", isTaken: false),
            MedicationWidgetData(id: UUID(), name: "Omega-3", dosage: "1000 mg", nextDoseTime: Date().addingTimeInterval(3600), colorName: "blue", isTaken: false),
            MedicationWidgetData(id: UUID(), name: "Multivitamin", dosage: "1 tablet", nextDoseTime: Date().addingTimeInterval(7200), colorName: "green", isTaken: true)
        ]
    }

    private func loadNextDose() -> MedicationWidgetData? {
        return MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date().addingTimeInterval(1800), colorName: "orange", isTaken: false)
    }
}

// MARK: - Widget Views

struct MedicationsWidgetEntryView: View {
    var entry: MedicationsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallMedicationView(entry: entry)
        case .systemMedium:
            MediumMedicationView(entry: entry)
        case .systemLarge:
            LargeMedicationView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularMedicationView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularMedicationView(entry: entry)
        default:
            SmallMedicationView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallMedicationView: View {
    let entry: MedicationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Spacer()
                Text("\(entry.completedToday)/\(entry.totalToday)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let nextDose = entry.nextDose {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Dose")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(nextDose.name)
                        .font(.headline)
                        .lineLimit(1)

                    if let time = nextDose.nextDoseTime {
                        Text(time, style: .time)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
            } else {
                Text("All done for today!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumMedicationView: View {
    let entry: MedicationEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "pills.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("Medications")
                        .font(.headline)
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(entry.completedToday)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("of \(entry.totalToday)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 70, height: 70)
            }
            .frame(maxWidth: .infinity)

            // Right side - Today's schedule
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's Schedule")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(entry.medications.prefix(3)) { med in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorFor(med.colorName))
                            .frame(width: 8, height: 8)

                        Text(med.name)
                            .font(.subheadline)
                            .lineLimit(1)

                        Spacer()

                        if med.isTaken {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else if let time = med.nextDoseTime {
                            Text(time, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if entry.medications.count > 3 {
                    Text("+\(entry.medications.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var progressValue: Double {
        guard entry.totalToday > 0 else { return 0 }
        return Double(entry.completedToday) / Double(entry.totalToday)
    }

    private func colorFor(_ name: String) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
}

// MARK: - Large Widget

struct LargeMedicationView: View {
    let entry: MedicationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Today's Medications")
                    .font(.headline)

                Spacer()

                Text("\(entry.completedToday)/\(entry.totalToday) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.green)
                        .frame(width: geometry.size.width * progressValue, height: 8)
                }
            }
            .frame(height: 8)

            Divider()

            // Medications list
            VStack(spacing: 10) {
                ForEach(entry.medications) { med in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(colorFor(med.colorName))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(med.dosage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if med.isTaken {
                            Label("Taken", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else if let time = med.nextDoseTime {
                            VStack(alignment: .trailing) {
                                Text(time, style: .time)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(time, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var progressValue: Double {
        guard entry.totalToday > 0 else { return 0 }
        return Double(entry.completedToday) / Double(entry.totalToday)
    }

    private func colorFor(_ name: String) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularMedicationView: View {
    let entry: MedicationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "pills.fill")
                    .font(.title3)
                Text("\(entry.completedToday)/\(entry.totalToday)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
    }
}

struct AccessoryRectangularMedicationView: View {
    let entry: MedicationEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label("Medications", systemImage: "pills.fill")
                    .font(.caption)

                if let nextDose = entry.nextDose {
                    Text(nextDose.name)
                        .font(.headline)
                    if let time = nextDose.nextDoseTime {
                        Text(time, style: .time)
                            .font(.caption)
                    }
                } else {
                    Text("All done!")
                        .font(.headline)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Widget Configuration

struct MedicationsWidget: Widget {
    let kind: String = "MedicationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MedicationsProvider()) { entry in
            MedicationsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Medications")
        .description("Track your medication schedule and never miss a dose.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MedicationsWidget()
} timeline: {
    MedicationEntry(
        date: Date(),
        medications: [
            MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date(), colorName: "orange", isTaken: false)
        ],
        nextDose: MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date(), colorName: "orange", isTaken: false),
        completedToday: 2,
        totalToday: 4
    )
}

#Preview(as: .systemMedium) {
    MedicationsWidget()
} timeline: {
    MedicationEntry(
        date: Date(),
        medications: [
            MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date(), colorName: "orange", isTaken: false),
            MedicationWidgetData(id: UUID(), name: "Omega-3", dosage: "1000 mg", nextDoseTime: Date().addingTimeInterval(3600), colorName: "blue", isTaken: true),
            MedicationWidgetData(id: UUID(), name: "Multivitamin", dosage: "1 tablet", nextDoseTime: nil, colorName: "green", isTaken: true)
        ],
        nextDose: MedicationWidgetData(id: UUID(), name: "Vitamin D", dosage: "1000 IU", nextDoseTime: Date(), colorName: "orange", isTaken: false),
        completedToday: 2,
        totalToday: 4
    )
}
