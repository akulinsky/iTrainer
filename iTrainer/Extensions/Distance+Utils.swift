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
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .meters:
            "m"
        case .kilometers:
            "km"
        }
    }
    
    static func preferred(forMeters value: Float) -> DistanceInputUnit {
        value >= 1000 ? .kilometers : .meters
    }
    
    func textValue(forMeters value: Float) -> String {
        switch self {
        case .meters:
            "\(Int(value))"
        case .kilometers:
            (value / 1000).formattedTrimmed(maxFractionDigits: 2)
        }
    }
    
    func meters(fromInputValue value: Float) -> Float {
        switch self {
        case .meters:
            value
        case .kilometers:
            value * 1000
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
    
    var distanceForDisplay: String {
        "\(distanceValueForDisplay) \(distanceUnitForDisplay)"
    }
    
    var distanceValueForDisplay: String {
        guard self >= 1000 else {
            return "\(Int(self))"
        }
        
        let kilometers = self / 1000
        return kilometers.formattedTrimmed(maxFractionDigits: 2)
    }
    
    var distanceUnitForDisplay: String {
        self >= 1000 ? "km" : "m"
    }
    
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

private extension Float {
    func formattedTrimmed(maxFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
