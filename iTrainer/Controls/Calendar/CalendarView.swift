//
//  CalendarView.swift
//  iTrainer
//
//  Created by Codex on 06.07.2026.
//

import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var visibleMonth: Date
    
    let markers: [Date: CalendarDateMarker]
    let minimumMonth: Date
    let maximumMonth: Date
    let calendar: Calendar
    
    init(selectedDate: Binding<Date>,
         visibleMonth: Binding<Date>,
         markers: [Date: CalendarDateMarker],
         minimumMonth: Date,
         maximumMonth: Date,
         calendar: Calendar = .current) {
        self._selectedDate = selectedDate
        self._visibleMonth = visibleMonth
        self.markers = markers
        self.minimumMonth = calendar.calendarControlStartOfMonth(for: minimumMonth)
        self.maximumMonth = calendar.calendarControlStartOfMonth(for: maximumMonth)
        self.calendar = calendar
    }
    
    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            CalendarMonthPagerView(selectedDate: $selectedDate,
                                   visibleMonth: $visibleMonth,
                                   markers: markers,
                                   minimumMonth: minimumMonth,
                                   maximumMonth: maximumMonth,
                                   calendar: calendar)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(AppColor.surfacePrimary)
        .onAppear(perform: clampCurrentMonth)
    }
    
    private var monthHeader: some View {
        HStack {
            monthButton(systemImage: "chevron.left",
                        isEnabled: canMovePrevious,
                        action: moveToPreviousMonth)
            Spacer()
            Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
            monthButton(systemImage: "chevron.right",
                        isEnabled: canMoveNext,
                        action: moveToNextMonth)
        }
    }
    
    private func monthButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isEnabled ? AppColor.brandPrimary : AppColor.textSecondary.opacity(0.35))
                .frame(width: 40, height: 40)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColor.separatorSoft, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
    
    private func moveToPreviousMonth() {
        moveMonth(by: -1)
    }
    
    private func moveToNextMonth() {
        moveMonth(by: 1)
    }
    
    private func moveMonth(by offset: Int) {
        let targetMonth = calendar.calendarControlDateByAddingMonths(offset, to: visibleMonth)
        let clampedMonth = calendar.calendarControlClampedMonth(targetMonth,
                                                 minimumMonth: minimumMonth,
                                                 maximumMonth: maximumMonth)
        guard !calendar.calendarControlIsMonth(clampedMonth, sameAs: visibleMonth) else { return }
        visibleMonth = clampedMonth
    }
    
    private func clampCurrentMonth() {
        let clampedMonth = calendar.calendarControlClampedMonth(visibleMonth,
                                                 minimumMonth: minimumMonth,
                                                 maximumMonth: maximumMonth)
        if !calendar.calendarControlIsMonth(clampedMonth, sameAs: visibleMonth) {
            visibleMonth = clampedMonth
        }
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    @Previewable @State var visibleMonth = Date()
    
    CalendarView(selectedDate: $selectedDate,
                 visibleMonth: $visibleMonth,
                 markers: [Calendar.current.startOfDay(for: Date()): .personalRecord],
                 minimumMonth: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                 maximumMonth: Date())
}
