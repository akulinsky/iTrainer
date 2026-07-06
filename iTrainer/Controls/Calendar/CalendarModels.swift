//
//  CalendarModels.swift
//  iTrainer
//
//  Created by Codex on 06.07.2026.
//

import Foundation

enum CalendarDateMarker: Hashable {
    case workout
    case personalRecord
}

struct CalendarDay: Identifiable, Hashable {
    let id: String
    let date: Date?
    let dayNumber: Int?
    let marker: CalendarDateMarker?
    let isToday: Bool
    let isSelected: Bool
}

extension CalendarDateMarker {
    static func merged(_ markers: [CalendarDateMarker]) -> CalendarDateMarker? {
        guard !markers.isEmpty else { return nil }
        return markers.contains(.personalRecord) ? .personalRecord : .workout
    }
}

extension Calendar {
    func calendarControlStartOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
    
    func calendarControlDateByAddingMonths(_ months: Int, to date: Date) -> Date {
        self.date(byAdding: .month, value: months, to: calendarControlStartOfMonth(for: date)) ?? calendarControlStartOfMonth(for: date)
    }
    
    func calendarControlClampedMonth(_ month: Date, minimumMonth: Date, maximumMonth: Date) -> Date {
        let normalizedMonth = calendarControlStartOfMonth(for: month)
        let minimum = calendarControlStartOfMonth(for: minimumMonth)
        let maximum = calendarControlStartOfMonth(for: maximumMonth)
        
        if compare(normalizedMonth, to: minimum, toGranularity: .month) == .orderedAscending {
            return minimum
        }
        if compare(normalizedMonth, to: maximum, toGranularity: .month) == .orderedDescending {
            return maximum
        }
        return normalizedMonth
    }
    
    func calendarControlIsMonth(_ lhs: Date, sameAs rhs: Date) -> Bool {
        isDate(lhs, equalTo: rhs, toGranularity: .month)
    }
    
    func calendarControlDate(in month: Date, matchingDayFrom date: Date) -> Date {
        let targetMonth = calendarControlStartOfMonth(for: month)
        let selectedDay = component(.day, from: date)
        let dayRange = range(of: .day, in: .month, for: targetMonth)
        let day = min(selectedDay, dayRange?.count ?? selectedDay)
        return self.date(byAdding: .day, value: max(day - 1, 0), to: targetMonth) ?? targetMonth
    }
}
