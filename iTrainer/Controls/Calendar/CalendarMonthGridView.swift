//
//  CalendarMonthGridView.swift
//  iTrainer
//
//  Created by Codex on 06.07.2026.
//

import SwiftUI

struct CalendarMonthGridView: View {
    let month: Date
    let selectedDate: Date
    let today: Date
    let markers: [Date: CalendarDateMarker]
    let calendar: Calendar
    let onSelectDate: (Date) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            weekdayRow
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(days) { day in
                    CalendarDayCell(day: day) {
                        if let date = day.date {
                            onSelectDate(date)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    private var weekdayRow: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(calendar.calendarControlWeekdaySymbols, id: \.self) { title in
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var days: [CalendarDay] {
        let startOfMonth = calendar.calendarControlStartOfMonth(for: month)
        guard let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        let leadingEmptyDays = calendar.calendarControlLeadingEmptyDays(for: startOfMonth)
        var result = [CalendarDay]()
        
        for index in 0..<leadingEmptyDays {
            result.append(CalendarDay(id: "empty-\(index)",
                                      date: nil,
                                      dayNumber: nil,
                                      marker: nil,
                                      isToday: false,
                                      isSelected: false))
        }
        
        for day in dayRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else {
                continue
            }
            let normalizedDate = calendar.startOfDay(for: date)
            result.append(CalendarDay(id: String(normalizedDate.timeIntervalSinceReferenceDate),
                                      date: normalizedDate,
                                      dayNumber: day,
                                      marker: markers[normalizedDate],
                                      isToday: calendar.isDate(normalizedDate, inSameDayAs: today),
                                      isSelected: calendar.isDate(normalizedDate, inSameDayAs: selectedDate)))
        }
        
        return result
    }
}

#Preview {
    CalendarMonthGridView(month: Date(),
                          selectedDate: Date(),
                          today: Date(),
                          markers: [Calendar.current.startOfDay(for: Date()): .personalRecord],
                          calendar: .current,
                          onSelectDate: { _ in })
        .padding()
        .background(AppColor.backgroundPrimary)
}
