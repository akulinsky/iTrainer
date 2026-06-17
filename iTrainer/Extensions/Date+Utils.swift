//
//  Date+Utils.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import Foundation

extension Date {
    
    var beginningDay: Date {
        var components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second],
                                                         from: self)
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? self
    }
    
    var endingDay: Date {
        var components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second],
                                                         from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components) ?? self
    }
}
