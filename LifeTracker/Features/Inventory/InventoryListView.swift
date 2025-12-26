import SwiftUI
import SwiftData

struct InventoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.name) private var items: [InventoryItem]

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @State private var showingAddItem = false
    @State private var showingScanner = false
    @State private var scannedBarcode: String?
    @State private var showingScannedItemSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(
                        icon: "archivebox.fill",
                        title: "No Items",
                        message: "Start tracking your belongings by scanning or adding items",
                        buttonTitle: "Add Item"
                    ) {
                        showingAddItem = true
                    }
                } else {
                    itemsList
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search items")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingScanner = true
                        } label: {
                            Label("Scan Barcode", systemImage: "barcode.viewfinder")
                        }

                        Button {
                            showingAddItem = true
                        } label: {
                            Label("Add Manually", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Categories") {
                            selectedCategory = nil
                        }
                        Divider()
                        ForEach(ItemCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if let category = selectedCategory {
                                Text(category.rawValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddInventoryItemView()
            }
            .fullScreenCover(isPresented: $showingScanner) {
                BarcodeScannerView(scannedCode: $scannedBarcode)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingScannedItemSheet) {
                if let barcode = scannedBarcode {
                    ScannedItemSheet(barcode: barcode)
                }
            }
            .onChange(of: scannedBarcode) { _, newValue in
                if newValue != nil {
                    showingScannedItemSheet = true
                }
            }
        }
    }

    private var itemsList: some View {
        List {
            // Summary Card
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(totalValueDisplay)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(items.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding(.vertical, Theme.Spacing.sm)
            }

            // Items by Category
            ForEach(groupedItems.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { category in
                Section {
                    ForEach(groupedItems[category] ?? []) { item in
                        NavigationLink(destination: InventoryDetailView(item: item)) {
                            InventoryItemRow(item: item)
                        }
                    }
                    .onDelete { offsets in
                        deleteItems(in: category, at: offsets)
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filteredItems: [InventoryItem] {
        var result = items

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    private var groupedItems: [ItemCategory: [InventoryItem]] {
        Dictionary(grouping: filteredItems, by: { $0.category })
    }

    private var totalValueDisplay: String {
        let total = items.compactMap { $0.currentValue ?? $0.purchasePrice }.reduce(0, +)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: total)) ?? "$0"
    }

    private func deleteItems(in category: ItemCategory, at offsets: IndexSet) {
        let categoryItems = groupedItems[category] ?? []
        for index in offsets {
            let item = categoryItems[index]
            modelContext.delete(item)
        }
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Photo or placeholder
            if let firstPhoto = item.photos.first,
               let uiImage = UIImage(data: firstPhoto) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            } else {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Theme.secondaryBackground)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: item.category.icon)
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(item.fullName)
                        .font(.headline)
                        .lineLimit(1)

                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                if let subcategory = item.subcategory {
                    Text(subcategory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let price = item.displayPrice {
                    Text(price)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let location = item.location {
                Text(location)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.secondaryBackground)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct AddInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var brand = ""
    @State private var category: ItemCategory = .other
    @State private var subcategory = ""
    @State private var purchasePrice = ""
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                    TextField("Brand (optional)", text: $brand)
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

                    TextField("Location (optional)", text: $location)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveItem() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveItem() {
        let item = InventoryItem(
            name: name,
            category: category,
            subcategory: subcategory.isEmpty ? nil : subcategory,
            brand: brand.isEmpty ? nil : brand,
            purchasePrice: Double(purchasePrice),
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(item)
        dismiss()
    }
}

#Preview {
    InventoryListView()
        .modelContainer(for: InventoryItem.self, inMemory: true)
}
