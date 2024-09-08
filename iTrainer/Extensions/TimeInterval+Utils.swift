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
    
    var timeForDisplay: String {
        if hour > 0 {
            hourMinuteSecond
        } else {
            minuteSecond
        }
    }
    
    var timeForTextField: String {
        timeForDisplay
    }
    
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    
    var minuteForDisplay: Int {
        Int((self/60).truncatingRemainder(dividingBy: 1000))
    }
    
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
    
    static func timeForSet(value: Double) -> TimeInterval {
        
        let hours = Int((value/10000).truncatingRemainder(dividingBy: 100))
        let minutes = Int((value/100).truncatingRemainder(dividingBy: 100))
        let seconds = Int(value.truncatingRemainder(dividingBy: 100))
        
        return TimeInterval(seconds + minutes * 60 + hours * 3600)
    }
}
