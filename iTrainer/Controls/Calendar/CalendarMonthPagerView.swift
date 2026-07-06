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
    @State private var isRecentering = false
    
    var body: some View {
        TabView(selection: $pageIndex) {
            if canMovePrevious {
                monthGrid(offset: -1)
                    .tag(0)
            }
            monthGrid(offset: 0)
                .tag(1)
            if canMoveNext {
                monthGrid(offset: 1)
                    .tag(2)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 318)
        .onChange(of: pageIndex) { _, newValue in
            if isRecentering {
                resetToCenterPage()
                return
            }
            handlePageChange(newValue)
        }
        .onChange(of: visibleMonth) {
            if pageIndex != 1 {
                resetToCenterPage()
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
    
    private var canMovePrevious: Bool {
        calendar.compare(calendar.calendarControlStartOfMonth(for: visibleMonth),
                         to: calendar.calendarControlStartOfMonth(for: minimumMonth),
                         toGranularity: .month) == .orderedDescending
    }
    
    private var canMoveNext: Bool {
        calendar.compare(calendar.calendarControlStartOfMonth(for: visibleMonth),
                         to: calendar.calendarControlStartOfMonth(for: maximumMonth),
                         toGranularity: .month) == .orderedAscending
    }
    
    private func displayMonth(for offset: Int) -> Date {
        let targetMonth = calendar.calendarControlDateByAddingMonths(offset, to: visibleMonth)
        return calendar.calendarControlClampedMonth(targetMonth,
                                     minimumMonth: minimumMonth,
                                     maximumMonth: maximumMonth)
    }
    
    private func handlePageChange(_ newValue: Int) {
        guard newValue != 1 else { return }
        isRecentering = true
        
        let offset = newValue - 1
        let targetMonth = calendar.calendarControlDateByAddingMonths(offset, to: visibleMonth)
        let clampedMonth = calendar.calendarControlClampedMonth(targetMonth,
                                                 minimumMonth: minimumMonth,
                                                 maximumMonth: maximumMonth)
        
        if !calendar.calendarControlIsMonth(clampedMonth, sameAs: visibleMonth) {
            visibleMonth = clampedMonth
        }
        
        resetToCenterPage()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            isRecentering = false
        }
    }
    
    private func resetToCenterPage() {
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                pageIndex = 1
            }
        }
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        visibleMonth = calendar.calendarControlStartOfMonth(for: date)
    }
}
