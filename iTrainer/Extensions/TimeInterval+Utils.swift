//
//  TimeInterval+Utils.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 21.08.2024.
//

import Foundation

extension TimeInterval {
    var hourMinuteSecond: String {
        String(format:"%d:%02d:%02d", hour, minute, second)
    }
    
    var hourMinute: String {
        String(format:"%d hours %02d min", hour, minute)
    }
    
    var minuteSecond: String {
        String(format:"%d:%02d", minute, second)
    }
    
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
}
