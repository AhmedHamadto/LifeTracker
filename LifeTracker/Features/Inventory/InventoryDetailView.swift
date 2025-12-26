import SwiftUI
import SwiftData

struct InventoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: InventoryItem

    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingImagePicker = false
    @State private var selectedPhotoIndex = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Photos
                if !item.photos.isEmpty {
                    TabView(selection: $selectedPhotoIndex) {
                        ForEach(item.photos.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: item.photos[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                                    .padding(.horizontal)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 300)
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .fill(Theme.secondaryBackground)
                        .frame(height: 200)
                        .overlay {
                            VStack(spacing: Theme.Spacing.md) {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)

                                Button("Add Photo") {
                                    showingImagePicker = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal)
                }

                VStack(spacing: Theme.Spacing.lg) {
                    // Category & Location
                    HStack {
                        Label(item.category.rawValue, systemImage: item.category.icon)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.inventoryColor.opacity(0.15))
                            .foregroundStyle(Theme.inventoryColor)
                            .clipShape(Capsule())

                        if let subcategory = item.subcategory {
                            Text(subcategory)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.secondaryBackground)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }

                    // Price Info
                    if item.purchasePrice != nil || item.currentValue != nil {
                        HStack(spacing: Theme.Spacing.xl) {
                            if let price = item.displayPrice {
                                VStack(alignment: .leading) {
                                    Text("Purchase Price")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(price)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                            }

                            if let value = item.displayCurrentValue {
                                VStack(alignment: .leading) {
                                    Text("Current Value")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(value)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.green)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Theme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }

                    // Details
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Details")
                            .font(.headline)

                        VStack(spacing: Theme.Spacing.sm) {
                            if let brand = item.brand {
                                DetailRow(label: "Brand", value: brand)
                            }

                            if let model = item.model {
                                DetailRow(label: "Model", value: model)
                            }

                            if let barcode = item.barcode {
                                DetailRow(label: "Barcode", value: barcode)
                            }

                            if let serial = item.serialNumber {
                                DetailRow(label: "Serial Number", value: serial)
                            }

                            if let location = item.location {
                                DetailRow(label: "Location", value: location)
                            }

                            if let purchaseDate = item.purchaseDate {
                                DetailRow(label: "Purchased", value: purchaseDate.formatted(date: .long, time: .omitted))
                            }
                        }
                        .padding()
                        .background(Theme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Notes
                    if let notes = item.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Notes")
                                .font(.headline)

                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Timestamps
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        DetailRow(label: "Added", value: item.createdAt.formatted(date: .long, time: .shortened))
                        DetailRow(label: "Updated", value: item.updatedAt.formatted(date: .long, time: .shortened))
                    }
                    .padding()
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
                .padding(.horizontal)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .navigationTitle(item.fullName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        item.isFavorite.toggle()
                    } label: {
                        Label(
                            item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: item.isFavorite ? "star.slash" : "star"
                        )
                    }

                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Add Photo", systemImage: "camera")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditInventoryItemView(item: item)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                if let data = image.jpegData(compressionQuality: 0.8) {
                    item.photos.append(data)
                    item.updatedAt = Date()
                }
            }
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }

    private func deleteItem() {
        modelContext.delete(item)
        dismiss()
    }
}

struct EditInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: InventoryItem

    @State private var name: String
    @State private var brand: String
    @State private var model: String
    @State private var category: ItemCategory
    @State private var subcategory: String
    @State private var purchasePrice: String
    @State private var currentValue: String
    @State private var location: String
    @State private var serialNumber: String
    @State private var notes: String

    init(item: InventoryItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _brand = State(initialValue: item.brand ?? "")
        _model = State(initialValue: item.model ?? "")
        _category = State(initialValue: item.category)
        _subcategory = State(initialValue: item.subcategory ?? "")
        _purchasePrice = State(initialValue: item.purchasePrice.map { String($0) } ?? "")
        _currentValue = State(initialValue: item.currentValue.map { String($0) } ?? "")
        _location = State(initialValue: item.location ?? "")
        _serialNumber = State(initialValue: item.serialNumber ?? "")
        _notes = State(initialValue: item.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
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

                Section("Value") {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Current Value", text: $currentValue)
                        .keyboardType(.decimalPad)
                }

                Section("Additional Info") {
                    TextField("Location", text: $location)
                    TextField("Serial Number", text: $serialNumber)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        item.name = name
        item.brand = brand.isEmpty ? nil : brand
        item.model = model.isEmpty ? nil : model
        item.category = category
        item.subcategory = subcategory.isEmpty ? nil : subcategory
        item.purchasePrice = Double(purchasePrice)
        item.currentValue = Double(currentValue)
        item.location = location.isEmpty ? nil : location
        item.serialNumber = serialNumber.isEmpty ? nil : serialNumber
        item.notes = notes.isEmpty ? nil : notes
        item.updatedAt = Date()

        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
