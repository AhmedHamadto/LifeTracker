import Foundation
import Vision
import UIKit

actor VisionService {
    static let shared = VisionService()

    private init() {}

    /// Performs OCR on an image and returns extracted text
    func extractText(from imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "ar-SA"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Extracts text from multiple images
    func extractText(from images: [Data]) async throws -> String {
        var allText: [String] = []

        for imageData in images {
            let text = try await extractText(from: imageData)
            if !text.isEmpty {
                allText.append(text)
            }
        }

        return allText.joined(separator: "\n\n---\n\n")
    }

    /// Detects document type based on extracted text
    func detectDocumentCategory(from text: String) -> DocumentCategory {
        let lowercasedText = text.lowercased()

        // Medical indicators
        let medicalKeywords = ["prescription", "diagnosis", "patient", "doctor", "hospital", "clinic", "medical", "health", "rx", "medication", "dosage", "physician"]
        if medicalKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .medical
        }

        // Receipt indicators
        let receiptKeywords = ["receipt", "total", "subtotal", "tax", "payment", "paid", "change", "cash", "credit", "debit", "transaction"]
        if receiptKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .receipt
        }

        // Warranty indicators
        let warrantyKeywords = ["warranty", "guarantee", "valid until", "coverage", "terms and conditions", "manufacturer"]
        if warrantyKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .warranty
        }

        // ID indicators
        let idKeywords = ["driver license", "passport", "identification", "id card", "date of birth", "expiry", "license number"]
        if idKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .identification
        }

        // Insurance indicators
        let insuranceKeywords = ["insurance", "policy", "premium", "coverage", "beneficiary", "claim", "insured"]
        if insuranceKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .insurance
        }

        // Financial indicators
        let financialKeywords = ["bank", "account", "statement", "balance", "deposit", "withdrawal", "interest", "investment"]
        if financialKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .financial
        }

        // Legal indicators
        let legalKeywords = ["agreement", "contract", "hereby", "party", "witness", "notary", "legal", "court", "attorney"]
        if legalKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .legal
        }

        return .other
    }

    /// Extracts receipt data from text
    func extractReceiptData(from text: String) -> ReceiptData? {
        let lines = text.components(separatedBy: .newlines)

        var merchant: String?
        var total: Double?
        var date: Date?

        // Try to find merchant (usually first non-empty line)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && trimmed.count > 2 {
                merchant = trimmed
                break
            }
        }

        // Try to find total
        let totalPatterns = [
            "total[:\\s]+\\$?([0-9]+\\.?[0-9]*)",
            "amount[:\\s]+\\$?([0-9]+\\.?[0-9]*)",
            "grand total[:\\s]+\\$?([0-9]+\\.?[0-9]*)"
        ]

        for pattern in totalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                total = Double(text[range])
                break
            }
        }

        // Try to find date
        let datePatterns = [
            "\\d{1,2}/\\d{1,2}/\\d{2,4}",
            "\\d{1,2}-\\d{1,2}-\\d{2,4}",
            "\\d{4}-\\d{2}-\\d{2}"
        ]

        let dateFormatters = [
            "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy",
            "MM-dd-yyyy", "M-d-yyyy",
            "yyyy-MM-dd"
        ]

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let dateString = String(text[range])
                for format in dateFormatters {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let parsedDate = formatter.date(from: dateString) {
                        date = parsedDate
                        break
                    }
                }
                if date != nil { break }
            }
        }

        guard merchant != nil || total != nil || date != nil else {
            return nil
        }

        return ReceiptData(merchant: merchant, total: total, date: date)
    }
}

struct ReceiptData {
    let merchant: String?
    let total: Double?
    let date: Date?
}

enum VisionError: Error, LocalizedError {
    case invalidImage
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be processed"
        case .processingFailed:
            return "Text extraction failed"
        }
    }
}
