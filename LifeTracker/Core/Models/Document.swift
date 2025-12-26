import Foundation
import SwiftData

@Model
final class Document {
    var id: UUID
    var title: String
    var category: DocumentCategory
    var imageData: [Data]
    var extractedText: String?
    var tags: [String]
    var expiryDate: Date?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \Folder.documents)
    var folder: Folder?

    init(
        id: UUID = UUID(),
        title: String,
        category: DocumentCategory = .other,
        imageData: [Data] = [],
        extractedText: String? = nil,
        tags: [String] = [],
        expiryDate: Date? = nil,
        folder: Folder? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.imageData = imageData
        self.extractedText = extractedText
        self.tags = tags
        self.expiryDate = expiryDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.folder = folder
    }

    var isExpired: Bool {
        guard let expiryDate else { return false }
        return expiryDate < Date()
    }

    var isExpiringSoon: Bool {
        guard let expiryDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiryDate <= thirtyDaysFromNow && expiryDate > Date()
    }

    var pageCount: Int {
        imageData.count
    }
}

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case medical = "Medical"
    case receipt = "Receipt"
    case warranty = "Warranty"
    case identification = "ID"
    case insurance = "Insurance"
    case financial = "Financial"
    case legal = "Legal"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .medical: return "cross.case.fill"
        case .receipt: return "receipt.fill"
        case .warranty: return "checkmark.shield.fill"
        case .identification: return "person.text.rectangle.fill"
        case .insurance: return "building.columns.fill"
        case .financial: return "banknote.fill"
        case .legal: return "doc.text.fill"
        case .other: return "doc.fill"
        }
    }

    var color: String {
        switch self {
        case .medical: return "red"
        case .receipt: return "green"
        case .warranty: return "blue"
        case .identification: return "purple"
        case .insurance: return "orange"
        case .financial: return "mint"
        case .legal: return "brown"
        case .other: return "gray"
        }
    }
}
