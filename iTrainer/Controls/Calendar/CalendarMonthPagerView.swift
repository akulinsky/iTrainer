//
//  CalendarMonthPagerView.swift
//  iTrainer
//
//  Created by Codex on 06.07.2026.
//

import SwiftUI

struct CalendarMonthPagerView: View {
    @Binding var selectedDate: Date
    @Binding var visibleMonth: Date
    
    let markers: [Date: CalendarDateMarker]
    let minimumMonth: Date
    let maximumMonth: Date
    let calendar: Calendar
    
    @State private var pageIndex = 1
    
    var body: some View {
        TabView(selection: $pageIndex) {
            monthGrid(offset: -1)
                .tag(0)
            monthGrid(offset: 0)
                .tag(1)
            monthGrid(offset: 1)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 318)
        .onChange(of: pageIndex) { _, newValue in
            handlePageChange(newValue)
        }
        .onChange(of: visibleMonth) {
            if pageIndex != 1 {
                pageIndex = 1
            }
        }
    }
    
    private func monthGrid(offset: Int) -> some View {
        CalendarMonthGridView(month: displayMonth(for: offset),
                              selectedDate: selectedDate,
                              today: Date(),
                              markers: markers,
                              calendar: calendar,
                              onSelectDate: selectDate)
    }
    
    private func displayMonth(for offset: Int) -> Date {
        let targetMonth = calendar.calendarControlDateByAddingMonths(offset, to: visibleMonth)
        return calendar.calendarControlClampedMonth(targetMonth,
                                     minimumMonth: minimumMonth,
                                     maximumMonth: maximumMonth)
    }
    
    private func handlePageChange(_ newValue: Int) {
        guard newValue != 1 else { return }
        let offset = newValue - 1
        let targetMonth = calendar.calendarControlDateByAddingMonths(offset, to: visibleMonth)
        let clampedMonth = calendar.calendarControlClampedMonth(targetMonth,
                                                 minimumMonth: minimumMonth,
                                                 maximumMonth: maximumMonth)
        
        if !calendar.calendarControlIsMonth(clampedMonth, sameAs: visibleMonth) {
            visibleMonth = clampedMonth
            selectedDate = calendar.calendarControlDate(in: clampedMonth, matchingDayFrom: selectedDate)
        }
        
        DispatchQueue.main.async {
            pageIndex = 1
        }
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        visibleMonth = calendar.calendarControlStartOfMonth(for: date)
    }
}
