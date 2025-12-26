import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var icon: String
    var colorName: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var documents: [Document]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        colorName: String = "blue"
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.createdAt = Date()
        self.documents = []
    }

    var documentCount: Int {
        documents.count
    }
}
