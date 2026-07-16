//
//  Distance+Utils.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 28.08.2024.
//

import Foundation

enum DistanceInputUnit: String, CaseIterable, Identifiable {
    case meters
    case kilometers
    case feet
    case miles
    
    var id: Self { self }
    
    var title: String {
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
    
    static var metricUnits: [DistanceInputUnit] {
        [.meters, .kilometers]
    }
    
    static var imperialUnits: [DistanceInputUnit] {
        [.feet, .miles]
    }
    
    static func units(for distanceUnit: ResolvedDistanceUnit) -> [DistanceInputUnit] {
        switch distanceUnit {
        case .metric:
            metricUnits
        case .imperial:
            imperialUnits
        }
    }
    
    static func preferred(forMeters value: Float, distanceUnit: ResolvedDistanceUnit = .metric) -> DistanceInputUnit {
        switch distanceUnit {
        case .metric:
            value >= 1000 ? .kilometers : .meters
        case .imperial:
            value >= UnitFormatter.metersPerMile ? .miles : .feet
        }
    }
    
    func textValue(forMeters value: Float) -> String {
        switch self {
        case .meters:
            "\(Int(value.rounded()))"
        case .kilometers:
            (value / 1000).formattedTrimmed(maxFractionDigits: 2)
        case .feet:
            "\(Int((value / UnitFormatter.metersPerFoot).rounded()))"
        case .miles:
            (value / UnitFormatter.metersPerMile).formattedTrimmed(maxFractionDigits: 2)
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
    
    func sanitizedInputText(_ text: String) -> String {
        switch self {
        case .meters, .feet:
            return text.filter(\.isNumber)
        case .kilometers, .miles:
            var hasDecimalSeparator = false
            var result = ""
            
            for character in text.replacingOccurrences(of: ",", with: ".") {
                if character.isNumber {
                    result.append(character)
                } else if character == ".", !hasDecimalSeparator {
                    result.append(character)
                    hasDecimalSeparator = true
                }
            }
            return result
        }
    }
    
    func convertedText(from text: String, previousUnit: DistanceInputUnit) -> String {
        guard let value = Self.inputValue(from: text), value > 0 else {
            return text
        }
        
        let meters = previousUnit.meters(fromInputValue: value)
        return textValue(forMeters: meters)
    }
    
    static func inputValue(from text: String) -> Float? {
        let normalizedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Float(normalizedText)
    }
}

extension Float {
    
    var distanceForTextField: String {
        "\(Int(self))"
    }
    
    var kilom: Int {
        Int((self/1000).truncatingRemainder(dividingBy: 1000))
    }
    
    var meter: Int {
        Int(truncatingRemainder(dividingBy: 1000))
    }
    
    static func distanceForSet(value: Float) -> Float {
        
        return 0
    }
}

