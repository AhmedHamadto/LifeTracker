import XCTest
import SwiftData
@testable import LifeTracker

final class DocumentTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Document.self, Folder.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Creation Tests

    func testDocumentCreation() throws {
        let document = Document(
            title: "Test Document",
            category: .medical,
            imageData: [Data()],
            tags: ["test", "medical"]
        )

        context.insert(document)
        try context.save()

        XCTAssertNotNil(document.id)
        XCTAssertEqual(document.title, "Test Document")
        XCTAssertEqual(document.category, .medical)
        XCTAssertEqual(document.tags.count, 2)
        XCTAssertEqual(document.pageCount, 1)
    }

    func testDocumentWithFolder() throws {
        let folder = Folder(name: "Medical Records", icon: "folder.fill", colorName: "blue")
        let document = Document(title: "Lab Results", category: .medical, folder: folder)

        context.insert(folder)
        context.insert(document)
        try context.save()

        XCTAssertEqual(document.folder?.name, "Medical Records")
        XCTAssertEqual(folder.documentCount, 1)
    }

    // MARK: - Expiry Tests

    func testDocumentNotExpired() throws {
        let futureDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        let document = Document(title: "ID Card", category: .identification, expiryDate: futureDate)

        XCTAssertFalse(document.isExpired)
        XCTAssertFalse(document.isExpiringSoon)
    }

    func testDocumentExpired() throws {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let document = Document(title: "Old ID", category: .identification, expiryDate: pastDate)

        XCTAssertTrue(document.isExpired)
    }

    func testDocumentExpiringSoon() throws {
        let soonDate = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        let document = Document(title: "Expiring ID", category: .identification, expiryDate: soonDate)

        XCTAssertFalse(document.isExpired)
        XCTAssertTrue(document.isExpiringSoon)
    }

    func testDocumentNoExpiryDate() throws {
        let document = Document(title: "Receipt", category: .receipt)

        XCTAssertFalse(document.isExpired)
        XCTAssertFalse(document.isExpiringSoon)
    }

    // MARK: - Category Tests

    func testAllDocumentCategories() {
        let categories = DocumentCategory.allCases

        XCTAssertEqual(categories.count, 8)
        XCTAssertTrue(categories.contains(.medical))
        XCTAssertTrue(categories.contains(.receipt))
        XCTAssertTrue(categories.contains(.warranty))
        XCTAssertTrue(categories.contains(.identification))
        XCTAssertTrue(categories.contains(.insurance))
        XCTAssertTrue(categories.contains(.financial))
        XCTAssertTrue(categories.contains(.legal))
        XCTAssertTrue(categories.contains(.other))
    }

    func testCategoryIcons() {
        XCTAssertEqual(DocumentCategory.medical.icon, "cross.case.fill")
        XCTAssertEqual(DocumentCategory.receipt.icon, "receipt.fill")
        XCTAssertEqual(DocumentCategory.warranty.icon, "checkmark.shield.fill")
    }

    // MARK: - Page Count Tests

    func testPageCount() throws {
        let document = Document(
            title: "Multi-page",
            imageData: [Data(), Data(), Data()]
        )

        XCTAssertEqual(document.pageCount, 3)
    }

    func testEmptyPageCount() throws {
        let document = Document(title: "Empty", imageData: [])

        XCTAssertEqual(document.pageCount, 0)
    }
}
