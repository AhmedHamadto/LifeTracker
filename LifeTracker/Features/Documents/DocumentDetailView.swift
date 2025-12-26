import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var document: Document

    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var selectedPageIndex = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Image Gallery
                if !document.imageData.isEmpty {
                    TabView(selection: $selectedPageIndex) {
                        ForEach(document.imageData.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: document.imageData[index]) {
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
                    .frame(height: 400)

                    if document.pageCount > 1 {
                        Text("Page \(selectedPageIndex + 1) of \(document.pageCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: Theme.Spacing.lg) {
                    // Category Badge
                    HStack {
                        Label(document.category.rawValue, systemImage: document.category.icon)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.module(document.category.color).opacity(0.15))
                            .foregroundStyle(Color.module(document.category.color))
                            .clipShape(Capsule())

                        Spacer()

                        if document.isExpired {
                            Label("Expired", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.red)
                                .clipShape(Capsule())
                        } else if document.isExpiringSoon {
                            Label("Expiring Soon", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.orange)
                                .clipShape(Capsule())
                        }
                    }

                    // Expiry Date
                    if let expiryDate = document.expiryDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text("Expires: \(expiryDate.formatted(date: .long, time: .omitted))")
                                .foregroundStyle(document.isExpired ? .red : .secondary)
                            Spacer()
                        }
                        .font(.subheadline)
                    }

                    // Tags
                    if !document.tags.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Tags")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(document.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.secondaryBackground)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Extracted Text
                    if let text = document.extractedText, !text.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                Text("Extracted Text")
                                    .font(.headline)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = text
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            }

                            Text(text)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .padding()
                                .background(Theme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Details")
                            .font(.headline)

                        VStack(spacing: Theme.Spacing.sm) {
                            DetailRow(label: "Created", value: document.createdAt.formatted(date: .long, time: .shortened))
                            DetailRow(label: "Updated", value: document.updatedAt.formatted(date: .long, time: .shortened))
                            DetailRow(label: "Pages", value: "\(document.pageCount)")
                        }
                        .padding()
                        .background(Theme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
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
            EditDocumentView(document: document)
        }
        .alert("Delete Document", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteDocument()
            }
        } message: {
            Text("Are you sure you want to delete this document? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let firstImage = document.imageData.first,
               let uiImage = UIImage(data: firstImage) {
                ShareSheet(items: [uiImage])
            }
        }
    }

    private func deleteDocument() {
        modelContext.delete(document)
        dismiss()
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

struct EditDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var document: Document

    @State private var title: String
    @State private var category: DocumentCategory
    @State private var hasExpiryDate: Bool
    @State private var expiryDate: Date
    @State private var tags: [String]
    @State private var newTag = ""

    init(document: Document) {
        self.document = document
        _title = State(initialValue: document.title)
        _category = State(initialValue: document.category)
        _hasExpiryDate = State(initialValue: document.expiryDate != nil)
        _expiryDate = State(initialValue: document.expiryDate ?? Date())
        _tags = State(initialValue: document.tags)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Details") {
                    TextField("Title", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(DocumentCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }

                    Toggle("Has Expiry Date", isOn: $hasExpiryDate)

                    if hasExpiryDate {
                        DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                    }
                }

                Section("Tags") {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(text: tag) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }

                    HStack {
                        TextField("Add tag", text: $newTag)
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces).lowercased()
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
        }
        newTag = ""
    }

    private func saveChanges() {
        document.title = title
        document.category = category
        document.expiryDate = hasExpiryDate ? expiryDate : nil
        document.tags = tags
        document.updatedAt = Date()

        // Update expiry notification
        if hasExpiryDate {
            Task {
                await NotificationService.shared.scheduleExpiryReminder(for: document)
            }
        }

        dismiss()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
