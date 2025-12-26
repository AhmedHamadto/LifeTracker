import XCTest
import SwiftData
@testable import LifeTracker

final class InventoryItemTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([InventoryItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Creation Tests

    func testInventoryItemCreation() throws {
        let item = InventoryItem(
            name: "iPhone 15 Pro",
            category: .electronics,
            subcategory: "Phone",
            brand: "Apple",
            purchasePrice: 999.99,
            location: "Home Office"
        )

        context.insert(item)
        try context.save()

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "iPhone 15 Pro")
        XCTAssertEqual(item.category, .electronics)
        XCTAssertEqual(item.subcategory, "Phone")
        XCTAssertEqual(item.brand, "Apple")
        XCTAssertEqual(item.purchasePrice, 999.99)
        XCTAssertFalse(item.isFavorite)
    }

    // MARK: - Display Tests

    func testFullNameWithBrand() {
        let item = InventoryItem(name: "MacBook Pro", brand: "Apple")

        XCTAssertEqual(item.fullName, "Apple MacBook Pro")
    }

    func testFullNameWithoutBrand() {
        let item = InventoryItem(name: "Generic Mouse")

        XCTAssertEqual(item.fullName, "Generic Mouse")
    }

    func testDisplayPrice() {
        let item = InventoryItem(name: "Test", purchasePrice: 149.99, currency: "USD")

        XCTAssertNotNil(item.displayPrice)
        XCTAssertTrue(item.displayPrice!.contains("149"))
    }

    func testDisplayPriceNil() {
        let item = InventoryItem(name: "Test")

        XCTAssertNil(item.displayPrice)
    }

    func testDisplayCurrentValue() {
        let item = InventoryItem(name: "Test", currentValue: 500.00, currency: "USD")

        XCTAssertNotNil(item.displayCurrentValue)
        XCTAssertTrue(item.displayCurrentValue!.contains("500"))
    }

    // MARK: - Category Tests

    func testAllItemCategories() {
        let categories = ItemCategory.allCases

        XCTAssertEqual(categories.count, 13)
        XCTAssertTrue(categories.contains(.electronics))
        XCTAssertTrue(categories.contains(.clothing))
        XCTAssertTrue(categories.contains(.gym))
        XCTAssertTrue(categories.contains(.kitchen))
    }

    func testCategoryIcons() {
        XCTAssertEqual(ItemCategory.electronics.icon, "desktopcomputer")
        XCTAssertEqual(ItemCategory.clothing.icon, "tshirt.fill")
        XCTAssertEqual(ItemCategory.gym.icon, "dumbbell.fill")
        XCTAssertEqual(ItemCategory.kitchen.icon, "refrigerator.fill")
    }

    func testCategorySubcategories() {
        let electronicsSubcategories = ItemCategory.electronics.subcategories

        XCTAssertTrue(electronicsSubcategories.contains("Phone"))
        XCTAssertTrue(electronicsSubcategories.contains("Laptop"))
        XCTAssertTrue(electronicsSubcategories.contains("Tablet"))

        let clothingSubcategories = ItemCategory.clothing.subcategories

        XCTAssertTrue(clothingSubcategories.contains("Tops"))
        XCTAssertTrue(clothingSubcategories.contains("Bottoms"))
        XCTAssertTrue(clothingSubcategories.contains("Shoes"))
    }

    func testOtherCategoryNoSubcategories() {
        XCTAssertTrue(ItemCategory.other.subcategories.isEmpty)
    }

    // MARK: - Photo Tests

    func testItemWithPhotos() {
        let item = InventoryItem(
            name: "Camera",
            photos: [Data(), Data()]
        )

        XCTAssertEqual(item.photos.count, 2)
    }

    // MARK: - Favorite Tests

    func testToggleFavorite() throws {
        let item = InventoryItem(name: "Favorite Item")
        context.insert(item)

        XCTAssertFalse(item.isFavorite)

        item.isFavorite = true
        try context.save()

        XCTAssertTrue(item.isFavorite)
    }

    // MARK: - Barcode Tests

    func testItemWithBarcode() {
        let item = InventoryItem(
            name: "Product",
            barcode: "1234567890123"
        )

        XCTAssertEqual(item.barcode, "1234567890123")
    }
}
