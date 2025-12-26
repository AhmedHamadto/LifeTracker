import SwiftUI
import SwiftData

struct ScannedItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let barcode: String

    @State private var isLoading = true
    @State private var productInfo: ProductInfo?
    @State private var error: String?

    // Form fields
    @State private var name = ""
    @State private var brand = ""
    @State private var category: ItemCategory = .other
    @State private var subcategory = ""
    @State private var purchasePrice = ""
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error {
                    errorView(error)
                } else {
                    formView
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                if !isLoading && error == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveItem() }
                            .disabled(name.isEmpty)
                    }
                }
            }
            .task {
                await lookupProduct()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Looking up product...")
                .foregroundStyle(.secondary)

            Text("Barcode: \(barcode)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Product Not Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Enter Manually") {
                error = nil
                name = ""
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var formView: some View {
        Form {
            if let productInfo {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Found via \(productInfo.source)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let brand = productInfo.brand {
                                Text(brand)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Product Match")
                }
            }

            Section("Item Details") {
                TextField("Name", text: $name)
                TextField("Brand", text: $brand)

                HStack {
                    Text("Barcode")
                    Spacer()
                    Text(barcode)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Category") {
                Picker("Category", selection: $category) {
                    ForEach(ItemCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }

                if !category.subcategories.isEmpty {
                    Picker("Subcategory", selection: $subcategory) {
                        Text("None").tag("")
                        ForEach(category.subcategories, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                }
            }

            Section("Purchase Info") {
                TextField("Purchase Price", text: $purchasePrice)
                    .keyboardType(.decimalPad)

                TextField("Location", text: $location)
            }

            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3)
            }
        }
    }

    private func lookupProduct() async {
        do {
            let info = try await BarcodeLookupService.shared.lookupProduct(barcode: barcode)

            await MainActor.run {
                if let info {
                    productInfo = info
                    name = info.name
                    brand = info.brand ?? ""
                    category = info.suggestedItemCategory
                } else {
                    error = "No product information found for this barcode. You can enter the details manually."
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to look up product: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func saveItem() {
        let item = InventoryItem(
            name: name,
            category: category,
            subcategory: subcategory.isEmpty ? nil : subcategory,
            brand: brand.isEmpty ? nil : brand,
            barcode: barcode,
            purchasePrice: Double(purchasePrice),
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(item)
        dismiss()
    }
}

#Preview {
    ScannedItemSheet(barcode: "5901234123457")
        .modelContainer(for: InventoryItem.self, inMemory: true)
}
