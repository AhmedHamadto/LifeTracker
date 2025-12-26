import Foundation

/// Unified error type for the LifeTracker app
enum AppError: LocalizedError, Equatable {

    // MARK: - Data Errors

    case dataNotFound(entity: String)
    case saveFailed(reason: String)
    case deleteFailed(reason: String)
    case fetchFailed(reason: String)
    case validationFailed(field: String, reason: String)

    // MARK: - Document Errors

    case documentScanFailed(reason: String)
    case ocrFailed(reason: String)
    case documentExportFailed(reason: String)
    case unsupportedDocumentFormat

    // MARK: - Camera/Photo Errors

    case cameraNotAvailable
    case cameraAccessDenied
    case photoLibraryAccessDenied
    case imageProcessingFailed

    // MARK: - Barcode Errors

    case barcodeScanFailed
    case barcodeNotRecognized
    case productLookupFailed(barcode: String)
    case productNotFound(barcode: String)

    // MARK: - HealthKit Errors

    case healthKitNotAvailable
    case healthKitAuthorizationDenied
    case healthKitReadFailed(dataType: String)
    case healthKitWriteFailed(dataType: String)

    // MARK: - Notification Errors

    case notificationPermissionDenied
    case notificationScheduleFailed(reason: String)

    // MARK: - Network Errors

    case networkUnavailable
    case requestFailed(statusCode: Int)
    case invalidResponse
    case decodingFailed(reason: String)

    // MARK: - CloudKit/Sync Errors

    case syncFailed(reason: String)
    case cloudKitNotAvailable
    case iCloudAccountNotAvailable

    // MARK: - Generic Errors

    case unknown(message: String)
    case custom(title: String, message: String)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .dataNotFound(let entity):
            return "\(entity) not found"
        case .saveFailed(let reason):
            return "Failed to save: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete: \(reason)"
        case .fetchFailed(let reason):
            return "Failed to fetch data: \(reason)"
        case .validationFailed(let field, let reason):
            return "\(field): \(reason)"

        case .documentScanFailed(let reason):
            return "Document scan failed: \(reason)"
        case .ocrFailed(let reason):
            return "Text recognition failed: \(reason)"
        case .documentExportFailed(let reason):
            return "Export failed: \(reason)"
        case .unsupportedDocumentFormat:
            return "Unsupported document format"

        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .cameraAccessDenied:
            return "Camera access was denied. Please enable it in Settings."
        case .photoLibraryAccessDenied:
            return "Photo library access was denied. Please enable it in Settings."
        case .imageProcessingFailed:
            return "Failed to process image"

        case .barcodeScanFailed:
            return "Failed to scan barcode"
        case .barcodeNotRecognized:
            return "Barcode format not recognized"
        case .productLookupFailed(let barcode):
            return "Failed to look up product: \(barcode)"
        case .productNotFound(let barcode):
            return "No product found for barcode: \(barcode)"

        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .healthKitAuthorizationDenied:
            return "HealthKit access was denied. Please enable it in Settings."
        case .healthKitReadFailed(let dataType):
            return "Failed to read \(dataType) from Health"
        case .healthKitWriteFailed(let dataType):
            return "Failed to save \(dataType) to Health"

        case .notificationPermissionDenied:
            return "Notification permission was denied. Please enable it in Settings."
        case .notificationScheduleFailed(let reason):
            return "Failed to schedule notification: \(reason)"

        case .networkUnavailable:
            return "No internet connection"
        case .requestFailed(let statusCode):
            return "Request failed with status code: \(statusCode)"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingFailed(let reason):
            return "Failed to process data: \(reason)"

        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        case .cloudKitNotAvailable:
            return "iCloud is not available"
        case .iCloudAccountNotAvailable:
            return "Please sign in to iCloud in Settings"

        case .unknown(let message):
            return message
        case .custom(_, let message):
            return message
        }
    }

    var failureReason: String? {
        errorDescription
    }

    var recoverySuggestion: String? {
        switch self {
        case .cameraAccessDenied, .photoLibraryAccessDenied, .healthKitAuthorizationDenied, .notificationPermissionDenied:
            return "Go to Settings > LifeTracker to enable access"
        case .networkUnavailable:
            return "Please check your internet connection and try again"
        case .iCloudAccountNotAvailable:
            return "Go to Settings > Apple ID > iCloud to sign in"
        default:
            return nil
        }
    }

    // MARK: - Error Metadata

    var title: String {
        switch self {
        case .custom(let title, _):
            return title
        case .dataNotFound, .saveFailed, .deleteFailed, .fetchFailed:
            return "Data Error"
        case .documentScanFailed, .ocrFailed, .documentExportFailed, .unsupportedDocumentFormat:
            return "Document Error"
        case .cameraNotAvailable, .cameraAccessDenied, .photoLibraryAccessDenied, .imageProcessingFailed:
            return "Camera Error"
        case .barcodeScanFailed, .barcodeNotRecognized, .productLookupFailed, .productNotFound:
            return "Barcode Error"
        case .healthKitNotAvailable, .healthKitAuthorizationDenied, .healthKitReadFailed, .healthKitWriteFailed:
            return "Health Error"
        case .notificationPermissionDenied, .notificationScheduleFailed:
            return "Notification Error"
        case .networkUnavailable, .requestFailed, .invalidResponse, .decodingFailed:
            return "Network Error"
        case .syncFailed, .cloudKitNotAvailable, .iCloudAccountNotAvailable:
            return "Sync Error"
        case .validationFailed:
            return "Validation Error"
        case .unknown:
            return "Error"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .syncFailed, .iCloudAccountNotAvailable:
            return true
        default:
            return false
        }
    }

    var requiresUserAction: Bool {
        switch self {
        case .cameraAccessDenied, .photoLibraryAccessDenied, .healthKitAuthorizationDenied,
             .notificationPermissionDenied, .iCloudAccountNotAvailable:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Conversion

extension AppError {
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        let nsError = error as NSError

        // Handle common error domains
        switch nsError.domain {
        case NSURLErrorDomain:
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return .networkUnavailable
            }
            return .requestFailed(statusCode: nsError.code)

        case "CKErrorDomain":
            return .syncFailed(reason: error.localizedDescription)

        default:
            return .unknown(message: error.localizedDescription)
        }
    }
}
