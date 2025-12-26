import SwiftUI
import SwiftData

struct DocumentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.createdAt, order: .reverse) private var documents: [Document]

    @State private var searchText = ""
    @State private var selectedCategory: DocumentCategory?
    @State private var showingScanner = false
    @State private var showingAddDocument = false

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    EmptyStateView(
                        icon: "doc.fill",
                        title: "No Documents",
                        message: "Start by scanning or uploading your first document",
                        buttonTitle: "Scan Document"
                    ) {
                        showingScanner = true
                    }
                } else {
                    documentsList
                }
            }
            .navigationTitle("Documents")
            .searchable(text: $searchText, prompt: "Search documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingScanner = true
                        } label: {
                            Label("Scan Document", systemImage: "doc.viewfinder")
                        }

                        Button {
                            showingAddDocument = true
                        } label: {
                            Label("Upload Photo", systemImage: "photo")
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
                        ForEach(DocumentCategory.allCases) { category in
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
        }
    }

    private var documentsList: some View {
        List {
            ForEach(filteredDocuments) { document in
                DocumentRowView(document: document)
            }
            .onDelete(perform: deleteDocuments)
        }
        .listStyle(.plain)
    }

    private var filteredDocuments: [Document] {
        var result = documents

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter { document in
                document.title.localizedCaseInsensitiveContains(searchText) ||
                (document.extractedText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                document.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return result
    }

    private func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            let document = filteredDocuments[index]
            modelContext.delete(document)
        }
    }
}

struct DocumentRowView: View {
    let document: Document

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Thumbnail
            if let firstImage = document.imageData.first,
               let uiImage = UIImage(data: firstImage) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            } else {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Color.module(document.category.color).opacity(0.2))
                    .frame(width: 50, height: 60)
                    .overlay {
                        Image(systemName: document.category.icon)
                            .foregroundStyle(Color.module(document.category.color))
                    }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(document.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Label(document.category.rawValue, systemImage: document.category.icon)
                        .font(.caption)
                        .foregroundStyle(Color.module(document.category.color))

                    if document.pageCount > 1 {
                        Text("• \(document.pageCount) pages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let expiryDate = document.expiryDate {
                    Text("Expires \(expiryDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(document.isExpired ? .red : (document.isExpiringSoon ? .orange : .secondary))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    DocumentsListView()
        .modelContainer(for: Document.self, inMemory: true)
}
