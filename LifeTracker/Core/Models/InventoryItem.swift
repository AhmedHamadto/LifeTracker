import Foundation
import SwiftData

@Model
final class InventoryItem {
    var id: UUID
    var name: String
    var category: ItemCategory
    var subcategory: String?
    var brand: String?
    var model: String?
    var barcode: String?
    var photos: [Data]
    var purchaseDate: Date?
    var purchasePrice: Double?
    var currentValue: Double?
    var currency: String
    var location: String?
    var serialNumber: String?
    var notes: String?
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    var warrantyDocumentId: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        category: ItemCategory = .other,
        subcategory: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        barcode: String? = nil,
        photos: [Data] = [],
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        currentValue: Double? = nil,
        currency: String = "USD",
        location: String? = nil,
        serialNumber: String? = nil,
        notes: String? = nil,
        warrantyDocumentId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.brand = brand
        self.model = model
        self.barcode = barcode
        self.photos = photos
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.currentValue = currentValue
        self.currency = currency
        self.location = location
        self.serialNumber = serialNumber
        self.notes = notes
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.warrantyDocumentId = warrantyDocumentId
    }

    var displayPrice: String? {
        guard let price = purchasePrice else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price))
    }

    var displayCurrentValue: String? {
        guard let value = currentValue else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: value))
    }

    var fullName: String {
        if let brand = brand {
            return "\(brand) \(name)"
        }
        return name
    }
}

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case electronics = "Electronics"
    case clothing = "Clothing"
    case gym = "Gym & Fitness"
    case kitchen = "Kitchen"
    case furniture = "Furniture"
    case tools = "Tools"
    case books = "Books"
    case sports = "Sports"
    case accessories = "Accessories"
    case personal = "Personal Care"
    case office = "Office"
    case outdoor = "Outdoor"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .electronics: return "desktopcomputer"
        case .clothing: return "tshirt.fill"
        case .gym: return "dumbbell.fill"
        case .kitchen: return "refrigerator.fill"
        case .furniture: return "sofa.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .books: return "book.fill"
        case .sports: return "sportscourt.fill"
        case .accessories: return "bag.fill"
        case .personal: return "comb.fill"
        case .office: return "pencil.and.ruler.fill"
        case .outdoor: return "tent.fill"
        case .other: return "shippingbox.fill"
        }
    }

    var subcategories: [String] {
        switch self {
        case .electronics:
            return ["Phone", "Laptop", "Tablet", "TV", "Camera", "Audio", "Gaming", "Wearables", "Accessories"]
        case .clothing:
            return ["Tops", "Bottoms", "Outerwear", "Shoes", "Formal", "Athletic", "Underwear", "Accessories"]
        case .gym:
            return ["Equipment", "Weights", "Accessories", "Supplements", "Bags", "Apparel"]
        case .kitchen:
            return ["Appliances", "Cookware", "Utensils", "Storage", "Gadgets"]
        case .furniture:
            return ["Living Room", "Bedroom", "Office", "Outdoor", "Storage"]
        case .tools:
            return ["Power Tools", "Hand Tools", "Garden", "Automotive"]
        case .books:
            return ["Fiction", "Non-Fiction", "Technical", "Educational"]
        case .sports:
            return ["Equipment", "Apparel", "Accessories", "Protective Gear"]
        case .accessories:
            return ["Bags", "Watches", "Jewelry", "Wallets", "Sunglasses"]
        case .personal:
            return ["Skincare", "Haircare", "Grooming", "Fragrance"]
        case .office:
            return ["Supplies", "Electronics", "Furniture", "Organization"]
        case .outdoor:
            return ["Camping", "Hiking", "Travel", "Beach"]
        case .other:
            return []
        }
    }
}
