//
//  MonthPickerSheet.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import SwiftUI

struct MonthPickerSheet: View {
    let selectedMonth: Date
    let availableYears: [Int]
    let onCancel: () -> Void
    let onSelect: (Date) -> Void
    
    @State private var selectedMonthNumber: Int
    @State private var selectedYear: Int
    
    private let calendar = Calendar.current
    private let monthSymbols = Calendar.current.monthSymbols
    
    init(selectedMonth: Date,
         availableYears: [Int],
         onCancel: @escaping () -> Void,
         onSelect: @escaping (Date) -> Void) {
        self.selectedMonth = selectedMonth
        self.availableYears = availableYears.isEmpty ? [Calendar.current.component(.year, from: Date())] : availableYears
        self.onCancel = onCancel
        self.onSelect = onSelect
        _selectedMonthNumber = State(initialValue: Calendar.current.component(.month, from: selectedMonth))
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: selectedMonth))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Picker("reports.month_picker.month", selection: $selectedMonthNumber) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthSymbols[month - 1])
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    Picker("reports.month_picker.year", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .padding(.horizontal, 12)
                
                Spacer(minLength: 0)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("reports.month_picker.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("reports.common.cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("reports.month_picker.select") {
                        onSelect(selectedDate)
                    }
                }
            }
        }
    }
    
    private var selectedDate: Date {
        calendar.date(from: DateComponents(year: selectedYear,
                                           month: selectedMonthNumber,
                                           day: 1)) ?? selectedMonth
    }
}

#Preview {
    MonthPickerSheet(selectedMonth: Date(),
                     availableYears: [2024, 2025, 2026],
                     onCancel: {},
                     onSelect: { _ in })
}
