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
    
    @State private var scrollPosition: Int?
    
    private let pagerHeight: CGFloat = 318
    
    private var visibleMonthIndex: Int {
        monthIndex(for: visibleMonth)
    }
    
    private var monthCount: Int {
        max(calendar.dateComponents([.month],
                                    from: calendar.calendarControlStartOfMonth(for: minimumMonth),
                                    to: calendar.calendarControlStartOfMonth(for: maximumMonth)).month ?? 0, 0) + 1
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<monthCount, id: \.self) { index in
                        monthGrid(index: index)
                            .frame(width: proxy.size.width)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition)
            .onAppear(perform: syncScrollPositionWithVisibleMonth)
            .onChange(of: scrollPosition) { _, newValue in
                guard let newValue else { return }
                let month = month(for: newValue)
                guard !calendar.calendarControlIsMonth(month, sameAs: visibleMonth) else { return }
                visibleMonth = month
            }
            .onChange(of: visibleMonth) {
                syncScrollPositionWithVisibleMonth()
            }
            .onChange(of: minimumMonth) {
                syncScrollPositionAfterBoundsChange()
            }
            .onChange(of: maximumMonth) {
                syncScrollPositionAfterBoundsChange()
            }
            .onChange(of: monthCount) {
                syncScrollPositionAfterBoundsChange()
            }
        }
        .frame(height: pagerHeight)
    }
    
    private func monthGrid(index: Int) -> some View {
        CalendarMonthGridView(month: month(for: index),
                              selectedDate: selectedDate,
                              today: Date(),
                              markers: markers,
                              calendar: calendar,
                              onSelectDate: selectDate)
    }
    
    private func month(for index: Int) -> Date {
        let clampedIndex = min(max(index, 0), monthCount - 1)
        return calendar.calendarControlDateByAddingMonths(clampedIndex, to: minimumMonth)
    }
    
    private func monthIndex(for month: Date) -> Int {
        let clampedMonth = calendar.calendarControlClampedMonth(month,
                                                                minimumMonth: minimumMonth,
                                                                maximumMonth: maximumMonth)
        let index = calendar.dateComponents([.month],
                                            from: calendar.calendarControlStartOfMonth(for: minimumMonth),
                                            to: calendar.calendarControlStartOfMonth(for: clampedMonth)).month ?? 0
        return min(max(index, 0), monthCount - 1)
    }
    
    private func syncScrollPositionWithVisibleMonth() {
        let index = visibleMonthIndex
        guard scrollPosition != index else { return }
        scrollPosition = index
    }
    
    private func syncScrollPositionAfterBoundsChange() {
        DispatchQueue.main.async {
            syncScrollPositionWithVisibleMonth()
        }
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        visibleMonth = calendar.calendarControlStartOfMonth(for: date)
    }
}
