import Foundation

enum Constants {
    enum App {
        static let name = "LifeTracker"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleId = Bundle.main.bundleIdentifier ?? "com.lifetracker.app"
    }

    enum UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredWeightUnit = "preferredWeightUnit"
        static let preferredMeasurementUnit = "preferredMeasurementUnit"
        static let preferredCurrency = "preferredCurrency"
        static let enableNotifications = "enableNotifications"
        static let enableHealthKitSync = "enableHealthKitSync"
    }

    enum Notifications {
        static let medicationReminder = "MEDICATION_REMINDER"
        static let refillReminder = "REFILL_REMINDER"
        static let documentExpiry = "DOCUMENT_EXPIRY"
    }

    enum Images {
        static let maxWidth: CGFloat = 1920
        static let maxHeight: CGFloat = 1920
        static let compressionQuality: CGFloat = 0.8
        static let thumbnailSize: CGFloat = 150
    }

    enum API {
        static let openFoodFactsBaseURL = "https://world.openfoodfacts.org/api/v0"
        static let upcDatabaseBaseURL = "https://api.upcitemdb.com/prod/trial"
    }

    enum Limits {
        static let maxDocumentPages = 50
        static let maxPhotosPerItem = 10
        static let maxTagsPerDocument = 20
        static let searchMinCharacters = 2
    }

    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.7
    }
}

// MARK: - Feature Flags

enum FeatureFlags {
    static let enableCloudSync = true
    static let enableHealthKit = true
    static let enableNotifications = true
    static let enableBarcodeScanning = true
    static let enableAIFeatures = true
}
