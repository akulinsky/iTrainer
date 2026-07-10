//
//  Distance+Utils.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 28.08.2024.
//

import Foundation

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
