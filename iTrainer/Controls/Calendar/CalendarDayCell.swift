//
//  CalendarDayCell.swift
//  iTrainer
//
//  Created by Codex on 06.07.2026.
//

import SwiftUI

struct CalendarDayCell: View {
    let day: CalendarDay
    let action: () -> Void
    
    private let selectionSize: CGFloat = 36
    private let markerSize: CGFloat = 7
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    selectionBackground
                    dayNumber
                }
                .frame(width: selectionSize, height: selectionSize)
                
                markerSlot
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(day.date == nil)
        .accessibilityLabel(accessibilityLabel)
    }
    
    @ViewBuilder
    private var selectionBackground: some View {
        if day.isSelected {
            Circle()
                .fill(AppColor.brandPrimary)
        } else if day.isToday {
            Circle()
                .fill(AppColor.brandPrimary.opacity(0.08))
        }
    }
    
    @ViewBuilder
    private var dayNumber: some View {
        if let dayNumber = day.dayNumber {
            Text("\(dayNumber)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(day.isSelected ? Color.white : AppColor.textPrimary)
        }
    }
    
    private var markerSlot: some View {
        ZStack {
            if let marker = day.marker {
                Circle()
                    .fill(markerColor(for: marker))
                    .frame(width: markerSize, height: markerSize)
            }
        }
        .frame(height: markerSize)
    }
    
    private var accessibilityLabel: String {
        guard let date = day.date else { return "Empty day" }
        return date.formatted(date: .complete, time: .omitted)
    }
    
    private func markerColor(for marker: CalendarDateMarker) -> Color {
        switch marker {
        case .workout:
            AppColor.progressGreen
        case .personalRecord:
            AppColor.restAmber
        }
    }
}

#Preview {
    HStack {
        CalendarDayCell(day: CalendarDay(id: "today",
                                         date: Date(),
                                         dayNumber: 6,
                                         marker: .workout,
                                         isToday: true,
                                         isSelected: false),
                        action: {})
        CalendarDayCell(day: CalendarDay(id: "selected",
                                         date: Date(),
                                         dayNumber: 14,
                                         marker: .personalRecord,
                                         isToday: false,
                                         isSelected: true),
                        action: {})
    }
    .padding()
    .background(AppColor.backgroundPrimary)
}