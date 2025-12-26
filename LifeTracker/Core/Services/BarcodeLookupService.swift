import Foundation

actor BarcodeLookupService {
    static let shared = BarcodeLookupService()

    private let session: URLSession
    private var cache: [String: ProductInfo] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    /// Looks up product information from a barcode using Open Food Facts API
    func lookupProduct(barcode: String) async throws -> ProductInfo? {
        // Check cache first
        if let cached = cache[barcode] {
            return cached
        }

        // Try Open Food Facts first (free, no API key needed)
        if let product = try await lookupOpenFoodFacts(barcode: barcode) {
            cache[barcode] = product
            return product
        }

        // Try UPC Database as fallback
        if let product = try await lookupUPCDatabase(barcode: barcode) {
            cache[barcode] = product
            return product
        }

        return nil
    }

    private func lookupOpenFoodFacts(barcode: String) async throws -> ProductInfo? {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw BarcodeError.invalidBarcode
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let status = json?["status"] as? Int, status == 1,
              let product = json?["product"] as? [String: Any] else {
            return nil
        }

        let name = product["product_name"] as? String
        let brand = product["brands"] as? String
        let category = product["categories"] as? String
        let imageUrl = product["image_url"] as? String

        guard let productName = name, !productName.isEmpty else {
            return nil
        }

        return ProductInfo(
            barcode: barcode,
            name: productName,
            brand: brand?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            category: category?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            imageUrl: imageUrl,
            source: "Open Food Facts"
        )
    }

    private func lookupUPCDatabase(barcode: String) async throws -> ProductInfo? {
        // UPC Database API (free tier available)
        // Note: In production, you'd want to use an API key
        let urlString = "https://api.upcitemdb.com/prod/trial/lookup?upc=\(barcode)"
        guard let url = URL(string: urlString) else {
            throw BarcodeError.invalidBarcode
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let items = json?["items"] as? [[String: Any]],
              let firstItem = items.first else {
            return nil
        }

        let name = firstItem["title"] as? String
        let brand = firstItem["brand"] as? String
        let category = firstItem["category"] as? String
        let images = firstItem["images"] as? [String]

        guard let productName = name, !productName.isEmpty else {
            return nil
        }

        return ProductInfo(
            barcode: barcode,
            name: productName,
            brand: brand,
            category: category,
            imageUrl: images?.first,
            source: "UPC Database"
        )
    }

    /// Clears the cache
    func clearCache() {
        cache.removeAll()
    }
}

struct ProductInfo: Sendable {
    let barcode: String
    let name: String
    let brand: String?
    let category: String?
    let imageUrl: String?
    let source: String

    var suggestedItemCategory: ItemCategory {
        guard let category = category?.lowercased() else { return .other }

        if category.contains("electronic") || category.contains("computer") || category.contains("phone") {
            return .electronics
        }
        if category.contains("cloth") || category.contains("apparel") || category.contains("wear") {
            return .clothing
        }
        if category.contains("gym") || category.contains("fitness") || category.contains("sport") {
            return .gym
        }
        if category.contains("kitchen") || category.contains("food") || category.contains("cook") {
            return .kitchen
        }
        if category.contains("furniture") || category.contains("home") {
            return .furniture
        }
        if category.contains("tool") {
            return .tools
        }
        if category.contains("book") {
            return .books
        }
        if category.contains("outdoor") || category.contains("garden") {
            return .outdoor
        }
        if category.contains("personal") || category.contains("beauty") || category.contains("health") {
            return .personal
        }
        if category.contains("office") || category.contains("stationery") {
            return .office
        }

        return .other
    }
}

enum BarcodeError: Error, LocalizedError {
    case invalidBarcode
    case networkError
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return "Invalid barcode format"
        case .networkError:
            return "Network error occurred"
        case .notFound:
            return "Product not found"
        }
    }
}
