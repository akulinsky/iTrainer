//
//  UnitFormatter.swift
//  iTrainer
//
//  Created by Codex on 16.07.2026.
//

import Foundation

struct UnitFormatter {
    static let kilogramsPerPound: Float = 0.45359237
    static let metersPerFoot: Float = 0.3048
    static let metersPerMile: Float = 1609.344
    
    let weightUnit: ResolvedWeightUnit
    let distanceUnit: ResolvedDistanceUnit
    
    init(settings: AppSettings) {
        self.weightUnit = settings.resolvedWeightUnit
        self.distanceUnit = settings.resolvedDistanceUnit
    }
    
    init(weightUnit: ResolvedWeightUnit, distanceUnit: ResolvedDistanceUnit) {
        self.weightUnit = weightUnit
        self.distanceUnit = distanceUnit
    }
    
    func weightValueForDisplay(kilograms: Float) -> Float {
        switch weightUnit {
        case .kilograms:
            kilograms
        case .pounds:
            kilograms / Self.kilogramsPerPound
        }
    }
    
    func kilograms(fromInputValue value: Float) -> Float {
        switch weightUnit {
        case .kilograms:
            value
        case .pounds:
            value * Self.kilogramsPerPound
        }
    }
    
    func weightText(kilograms: Float) -> String {
        weightValueForDisplay(kilograms: kilograms).formattedTrimmed(maxFractionDigits: 1)
    }
    
    var repetitionsUnitText: String {
        NSLocalizedString("unit.repetitions.short", comment: "Short repetitions unit label")
    }
    
    func weightTextWithUnit(kilograms: Float) -> String {
        "\(weightText(kilograms: kilograms)) \(weightUnit.symbol)"
    }
    
    func repetitionsText(_ value: Int) -> String {
        "\(value) \(repetitionsUnitText)"
    }
    
    func distanceText(meters: Float) -> String {
        switch distanceUnit {
        case .metric:
            return metricDistanceText(meters: meters)
        case .imperial:
            return imperialDistanceText(meters: meters)
        }
    }
    
    func distanceValueText(meters: Float) -> String {
        switch distanceUnit {
        case .metric:
            let unit = metricDistanceDisplayUnit(forMeters: meters)
            return unit.valueText(forMeters: meters)
        case .imperial:
            let unit = imperialDistanceDisplayUnit(forMeters: meters)
            return unit.valueText(forMeters: meters)
        }
    }
    
    func distanceUnitText(meters: Float) -> String {
        switch distanceUnit {
        case .metric:
            metricDistanceDisplayUnit(forMeters: meters).symbol
        case .imperial:
            imperialDistanceDisplayUnit(forMeters: meters).symbol
        }
    }
    
    func distanceGoalText(actualMeters: Float, targetMeters: Float) -> String {
        let unit: DistanceEntryUnit
        switch distanceUnit {
        case .metric:
            unit = metricDistanceDisplayUnit(forMeters: targetMeters)
        case .imperial:
            unit = imperialDistanceDisplayUnit(forMeters: targetMeters)
        }
        
        return "\(unit.valueText(forMeters: actualMeters)) / \(unit.valueText(forMeters: targetMeters)) \(unit.symbol)"
    }
    
    func meters(fromInputValue value: Float, unit: DistanceEntryUnit) -> Float {
        unit.meters(fromInputValue: value)
    }
    
    func paceText(secondsPerMeter: Float) -> String {
        "\(paceValueText(secondsPerMeter: secondsPerMeter))\(paceUnitText)"
    }
    
    func paceValueText(secondsPerMeter: Float) -> String {
        switch distanceUnit {
        case .metric:
            return TimeInterval(secondsPerMeter * 1000).timeForDisplay
        case .imperial:
            return TimeInterval(secondsPerMeter * Self.metersPerMile).timeForDisplay
        }
    }
    
    var paceUnitText: String {
        switch distanceUnit {
        case .metric:
            "/km"
        case .imperial:
            "/mi"
        }
    }
    
    private func metricDistanceText(meters: Float) -> String {
        let unit = metricDistanceDisplayUnit(forMeters: meters)
        return "\(unit.valueText(forMeters: meters)) \(unit.symbol)"
    }
    
    private func imperialDistanceText(meters: Float) -> String {
        let unit = imperialDistanceDisplayUnit(forMeters: meters)
        return "\(unit.valueText(forMeters: meters)) \(unit.symbol)"
    }
    
    private func metricDistanceDisplayUnit(forMeters meters: Float) -> DistanceEntryUnit {
        meters >= 1000 ? .kilometers : .meters
    }
    
    private func imperialDistanceDisplayUnit(forMeters meters: Float) -> DistanceEntryUnit {
        meters >= Self.metersPerMile ? .miles : .feet
    }
}

enum DistanceEntryUnit: String, CaseIterable, Identifiable {
    case meters
    case kilometers
    case feet
    case miles
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .meters:
            "m"
        case .kilometers:
            "km"
        case .feet:
            "ft"
        case .miles:
            "mi"
        }
    }
    
    func valueText(forMeters meters: Float) -> String {
        switch self {
        case .meters:
            return "\(Int(meters.rounded()))"
        case .kilometers:
            return (meters / 1000).formattedTrimmed(maxFractionDigits: 2)
        case .feet:
            return "\(Int((meters / UnitFormatter.metersPerFoot).rounded()))"
        case .miles:
            return (meters / UnitFormatter.metersPerMile).formattedTrimmed(maxFractionDigits: 2)
        }
    }
    
    func meters(fromInputValue value: Float) -> Float {
        switch self {
        case .meters:
            value
        case .kilometers:
            value * 1000
        case .feet:
            value * UnitFormatter.metersPerFoot
        case .miles:
            value * UnitFormatter.metersPerMile
        }
    }
}

extension Locale {
    var usesImperialMeasurements: Bool {
        if #available(iOS 16, *) {
            measurementSystem == .us || measurementSystem == .uk
        } else {
            usesMetricSystem == false
        }
    }
}

extension Float {
    func formattedTrimmed(maxFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
