import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onScanComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.onScanComplete(images)
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scan failed: \(error)")
            parent.dismiss()
        }
    }
}

struct DocumentScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var scannedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var showingScanner = true
    @State private var title = ""
    @State private var category: DocumentCategory = .other
    @State private var extractedText = ""
    @State private var expiryDate: Date?
    @State private var hasExpiryDate = false
    @State private var tags: [String] = []
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            if showingScanner {
                DocumentScannerView { images in
                    scannedImages = images
                    showingScanner = false
                    processScannedImages()
                }
                .ignoresSafeArea()
                .navigationBarHidden(true)
            } else {
                Form {
                    if !scannedImages.isEmpty {
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(scannedImages.indices, id: \.self) { index in
                                        Image(uiImage: scannedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Scanned Pages (\(scannedImages.count))")
                        }
                    }

                    Section("Document Details") {
                        TextField("Title", text: $title)

                        Picker("Category", selection: $category) {
                            ForEach(DocumentCategory.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }

                        Toggle("Has Expiry Date", isOn: $hasExpiryDate)

                        if hasExpiryDate {
                            DatePicker("Expiry Date", selection: Binding(
                                get: { expiryDate ?? Date() },
                                set: { expiryDate = $0 }
                            ), displayedComponents: .date)
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

                    if !extractedText.isEmpty {
                        Section("Extracted Text") {
                            Text(extractedText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(10)
                        }
                    }

                    if isProcessing {
                        Section {
                            HStack {
                                ProgressView()
                                Text("Processing document...")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("New Document")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveDocument() }
                            .disabled(title.isEmpty || isProcessing)
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            showingScanner = true
                        } label: {
                            Label("Scan More", systemImage: "doc.viewfinder")
                        }
                    }
                }
            }
        }
    }

    private func processScannedImages() {
        isProcessing = true

        Task {
            let imageDataArray = scannedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }

            do {
                let text = try await VisionService.shared.extractText(from: imageDataArray)
                await MainActor.run {
                    extractedText = text

                    // Auto-detect category
                    let detectedCategory = VisionService.shared.detectDocumentCategory(from: text)
                    category = detectedCategory

                    // Generate title suggestion
                    if title.isEmpty {
                        title = generateTitleSuggestion(from: text)
                    }

                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
                print("OCR Error: \(error)")
            }
        }
    }

    private func generateTitleSuggestion(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 3 && $0.count < 50 }

        if let firstLine = lines.first {
            return firstLine
        }

        return "\(category.rawValue) - \(Date().formatted(date: .abbreviated, time: .omitted))"
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces).lowercased()
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
        }
        newTag = ""
    }

    private func saveDocument() {
        let imageDataArray = scannedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }

        let document = Document(
            title: title,
            category: category,
            imageData: imageDataArray,
            extractedText: extractedText.isEmpty ? nil : extractedText,
            tags: tags,
            expiryDate: hasExpiryDate ? expiryDate : nil
        )

        modelContext.insert(document)

        // Schedule expiry notification if applicable
        if let _ = document.expiryDate {
            Task {
                await NotificationService.shared.scheduleExpiryReminder(for: document)
            }
        }

        dismiss()
    }
}

struct TagChip: View {
    let text: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.primary.opacity(0.15))
        .foregroundStyle(Theme.primary)
        .clipShape(Capsule())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}
