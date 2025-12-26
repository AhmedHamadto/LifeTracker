import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var id: UUID
    var date: Date
    var weight: Double?
    var weightUnit: WeightUnit
    var bodyFatPercentage: Double?
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var bicepLeft: Double?
    var bicepRight: Double?
    var thighLeft: Double?
    var thighRight: Double?
    var calfLeft: Double?
    var calfRight: Double?
    var measurementUnit: MeasurementUnit
    var photo: Data?
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weight: Double? = nil,
        weightUnit: WeightUnit = .kg,
        bodyFatPercentage: Double? = nil,
        chest: Double? = nil,
        waist: Double? = nil,
        hips: Double? = nil,
        bicepLeft: Double? = nil,
        bicepRight: Double? = nil,
        thighLeft: Double? = nil,
        thighRight: Double? = nil,
        calfLeft: Double? = nil,
        calfRight: Double? = nil,
        measurementUnit: MeasurementUnit = .cm,
        photo: Data? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.weightUnit = weightUnit
        self.bodyFatPercentage = bodyFatPercentage
        self.chest = chest
        self.waist = waist
        self.hips = hips
        self.bicepLeft = bicepLeft
        self.bicepRight = bicepRight
        self.thighLeft = thighLeft
        self.thighRight = thighRight
        self.calfLeft = calfLeft
        self.calfRight = calfRight
        self.measurementUnit = measurementUnit
        self.photo = photo
        self.notes = notes
        self.createdAt = Date()
    }

    var displayWeight: String? {
        guard let weight else { return nil }
        return String(format: "%.1f %@", weight, weightUnit.rawValue)
    }

    var displayBodyFat: String? {
        guard let bf = bodyFatPercentage else { return nil }
        return String(format: "%.1f%%", bf)
    }

    var measurementsSummary: [String: Double] {
        var summary: [String: Double] = [:]
        if let chest { summary["Chest"] = chest }
        if let waist { summary["Waist"] = waist }
        if let hips { summary["Hips"] = hips }
        if let bicepLeft { summary["Left Bicep"] = bicepLeft }
        if let bicepRight { summary["Right Bicep"] = bicepRight }
        if let thighLeft { summary["Left Thigh"] = thighLeft }
        if let thighRight { summary["Right Thigh"] = thighRight }
        if let calfLeft { summary["Left Calf"] = calfLeft }
        if let calfRight { summary["Right Calf"] = calfRight }
        return summary
    }
}

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case cm = "cm"
    case inches = "in"

    var id: String { rawValue }

    func convert(to unit: MeasurementUnit, value: Double) -> Double {
        if self == unit { return value }
        switch (self, unit) {
        case (.cm, .inches): return value / 2.54
        case (.inches, .cm): return value * 2.54
        default: return value
        }
    }
}
