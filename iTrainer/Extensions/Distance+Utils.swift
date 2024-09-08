//
//  Distance+Utils.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 28.08.2024.
//

import Foundation


extension Float {
    
    var distanceForDisplay: String {
//        String(format:"%d.%01d", kilom, meter)
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
