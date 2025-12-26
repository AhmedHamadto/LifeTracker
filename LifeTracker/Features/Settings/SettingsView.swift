import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredWeightUnit") private var weightUnit = "kg"
    @AppStorage("preferredMeasurementUnit") private var measurementUnit = "cm"
    @AppStorage("preferredCurrency") private var currency = "USD"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableHealthKitSync") private var enableHealthKitSync = true

    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                Section("Units") {
                    Picker("Weight", selection: $weightUnit) {
                        Text("Kilograms (kg)").tag("kg")
                        Text("Pounds (lbs)").tag("lbs")
                    }

                    Picker("Measurements", selection: $measurementUnit) {
                        Text("Centimeters (cm)").tag("cm")
                        Text("Inches (in)").tag("in")
                    }

                    Picker("Currency", selection: $currency) {
                        Text("USD ($)").tag("USD")
                        Text("EUR (€)").tag("EUR")
                        Text("GBP (£)").tag("GBP")
                        Text("AED (د.إ)").tag("AED")
                        Text("SAR (ر.س)").tag("SAR")
                    }
                }

                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)

                    if enableNotifications {
                        Button("Configure Notifications") {
                            Task {
                                await NotificationService.shared.requestAuthorization()
                            }
                        }
                    }
                }

                Section("Health") {
                    Toggle("Sync with Apple Health", isOn: $enableHealthKitSync)

                    if enableHealthKitSync {
                        Button("Connect Apple Health") {
                            Task {
                                await HealthKitService.shared.requestAuthorization()
                            }
                        }
                    }
                }

                Section("Data") {
                    NavigationLink {
                        ExportDataView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        ImportDataView()
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Constants.App.version) (\(Constants.App.build))")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/AhmedHamadto/LifeTracker")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }

                    Button("Rate on App Store") {
                        // Would open App Store rating
                    }

                    Button("Send Feedback") {
                        // Would open email composer
                    }
                }

                Section {
                    Button("Reset All Settings", role: .destructive) {
                        resetSettings()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func resetSettings() {
        weightUnit = "kg"
        measurementUnit = "cm"
        currency = "USD"
        enableNotifications = true
        enableHealthKitSync = true
    }
}

struct ExportDataView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Export Your Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Export all your data as a JSON file that you can backup or transfer to another device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Export All Data") {
                // Implement export
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Export Data")
    }
}

struct ImportDataView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Import Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Import data from a previously exported JSON file.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Select File") {
                // Implement import
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Import Data")
    }
}

#Preview {
    SettingsView()
}
