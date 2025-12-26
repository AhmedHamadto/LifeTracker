import SwiftUI
import SwiftData

struct AddMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var date = Date()
    @State private var weight = ""
    @State private var weightUnit: WeightUnit = .kg
    @State private var bodyFat = ""
    @State private var chest = ""
    @State private var waist = ""
    @State private var hips = ""
    @State private var bicepLeft = ""
    @State private var bicepRight = ""
    @State private var thighLeft = ""
    @State private var thighRight = ""
    @State private var measurementUnit: MeasurementUnit = .cm
    @State private var notes = ""
    @State private var photo: UIImage?
    @State private var showingImagePicker = false
    @State private var syncToHealth = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Body Composition") {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $weightUnit) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack {
                        TextField("Body Fat %", text: $bodyFat)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack {
                        Text("Measurement Unit")
                        Spacer()
                        Picker("Unit", selection: $measurementUnit) {
                            ForEach(MeasurementUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }

                    MeasurementField(label: "Chest", value: $chest, unit: measurementUnit)
                    MeasurementField(label: "Waist", value: $waist, unit: measurementUnit)
                    MeasurementField(label: "Hips", value: $hips, unit: measurementUnit)
                } header: {
                    Text("Body Measurements")
                }

                Section("Arms") {
                    MeasurementField(label: "Left Bicep", value: $bicepLeft, unit: measurementUnit)
                    MeasurementField(label: "Right Bicep", value: $bicepRight, unit: measurementUnit)
                }

                Section("Legs") {
                    MeasurementField(label: "Left Thigh", value: $thighLeft, unit: measurementUnit)
                    MeasurementField(label: "Right Thigh", value: $thighRight, unit: measurementUnit)
                }

                Section("Progress Photo") {
                    if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))

                        Button("Remove Photo", role: .destructive) {
                            self.photo = nil
                        }
                    } else {
                        Button("Add Photo") {
                            showingImagePicker = true
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }

                Section {
                    Toggle("Sync to Apple Health", isOn: $syncToHealth)
                } footer: {
                    Text("Weight and body fat will be saved to Apple Health if enabled")
                }
            }
            .navigationTitle("New Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMeasurement() }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    self.photo = image
                }
            }
        }
    }

    private func saveMeasurement() {
        let measurement = BodyMeasurement(
            date: date,
            weight: Double(weight),
            weightUnit: weightUnit,
            bodyFatPercentage: Double(bodyFat),
            chest: Double(chest),
            waist: Double(waist),
            hips: Double(hips),
            bicepLeft: Double(bicepLeft),
            bicepRight: Double(bicepRight),
            thighLeft: Double(thighLeft),
            thighRight: Double(thighRight),
            measurementUnit: measurementUnit,
            photo: photo?.jpegData(compressionQuality: 0.8),
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(measurement)

        // Sync to HealthKit
        if syncToHealth {
            Task {
                if let weightValue = Double(weight) {
                    try? await HealthKitService.shared.saveWeight(weightValue, unit: weightUnit, date: date)
                }
                if let bodyFatValue = Double(bodyFat) {
                    try? await HealthKitService.shared.saveBodyFat(bodyFatValue, date: date)
                }
            }
        }

        dismiss()
    }
}

struct MeasurementField: View {
    let label: String
    @Binding var value: String
    let unit: MeasurementUnit

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit.rawValue)
                .foregroundStyle(.secondary)
                .frame(width: 30)
        }
    }
}

struct MeasurementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let measurement: BodyMeasurement

    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Date Header
                Text(measurement.date.formatted(date: .long, time: .omitted))
                    .font(.title2)
                    .fontWeight(.bold)

                // Photo
                if let photoData = measurement.photo,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                        .padding(.horizontal)
                }

                // Body Composition
                if measurement.weight != nil || measurement.bodyFatPercentage != nil {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Body Composition")
                            .font(.headline)

                        HStack(spacing: Theme.Spacing.xl) {
                            if let weight = measurement.displayWeight {
                                StatBlock(title: "Weight", value: weight)
                            }

                            if let bf = measurement.displayBodyFat {
                                StatBlock(title: "Body Fat", value: bf)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal)
                }

                // Measurements
                if !measurement.measurementsSummary.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Measurements")
                            .font(.headline)

                        let summary = measurement.measurementsSummary
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                            ForEach(Array(summary.keys.sorted()), id: \.self) { key in
                                if let value = summary[key] {
                                    MeasurementStatBlock(
                                        title: key,
                                        value: "\(String(format: "%.1f", value)) \(measurement.measurementUnit.rawValue)"
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal)
                }

                // Notes
                if let notes = measurement.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Notes")
                            .font(.headline)

                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Measurement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Measurement", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(measurement)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this measurement?")
        }
    }
}

struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

struct MeasurementStatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }
}

#Preview {
    AddMeasurementView()
        .modelContainer(for: BodyMeasurement.self, inMemory: true)
}
