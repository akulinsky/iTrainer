//
//  ReportDashboardViewModel.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import Foundation

struct ReportsMonthSummary: Hashable {
    let monthTitle: String
    let workoutCountValueText: String
    let workoutCountTitleText: String
    let personalRecordValueText: String
    let personalRecordTitleText: String
    let totalVolumeValueText: String
    let totalVolumeTitleText: String
}

struct WorkoutReportCardItem: Identifiable, Hashable {
    let id: UUID
    let report: ReportWorkoutModel
    let title: String
    let groupTitle: String
    let dateText: String
    let timeText: String
    let status: WorkoutReportStatus
}

@MainActor
final class ReportDashboardViewModel: ObservableObject {
    
    @Published private(set) var isLoading = false
    @Published private(set) var selectedMonth: Date
    @Published private(set) var monthSummary: ReportsMonthSummary
    @Published private(set) var workoutReportCards = [WorkoutReportCardItem]()
    @Published private(set) var availableYears = [Int]()
    @Published var isMonthPickerPresented = false
    
    private var preparedRows = [ReportDashboardPreparedRow]()
    private let calendar: Calendar
    private let volumeFormatter: NumberFormatter
    private var unitFormatter: UnitFormatter { UnitFormatter(settings: AppSettings.shared) }
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.selectedMonth = calendar.startOfMonth(for: Date())
        let unitFormatter = UnitFormatter(settings: AppSettings.shared)
        self.monthSummary = ReportsMonthSummary(monthTitle: Self.monthTitle(for: Date(), calendar: calendar),
                                                workoutCountValueText: "0",
                                                workoutCountTitleText: "Workouts Completed",
                                                personalRecordValueText: "0",
                                                personalRecordTitleText: "Personal Records",
                                                totalVolumeValueText: unitFormatter.weightTextWithUnit(kilograms: 0),
                                                totalVolumeTitleText: "Total Volume")
        self.availableYears = [calendar.component(.year, from: Date())]
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        self.volumeFormatter = formatter
    }
    
    func reloadReports() async {
        
        isLoading = true
        let rows = await Task.detached(priority: .userInitiated) {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let snapshots = await dataManager.fetchCompletedReportDashboardSnapshots()
            return ReportDashboardDataBuilder().buildRows(from: snapshots)
        }.value
        
        preparedRows = rows
        availableYears = makeAvailableYears(from: preparedRows)
        applySelectedMonth()
        isLoading = false
    }
    
    func showMonthPicker() {
        isMonthPickerPresented = true
    }
    
    func selectMonth(_ month: Date) {
        selectedMonth = calendar.startOfMonth(for: month)
        applySelectedMonth()
    }
    
    private func applySelectedMonth() {
        let rows = preparedRows
            .filter { row in
                guard let startDate = row.report.startDate else { return false }
                return calendar.isDate(startDate, equalTo: selectedMonth, toGranularity: .month) &&
                    calendar.isDate(startDate, equalTo: selectedMonth, toGranularity: .year)
            }
            .sorted { ($0.report.startDate ?? .distantPast) > ($1.report.startDate ?? .distantPast) }
        
        let personalRecordCount = rows.reduce(0) { partialResult, row in
            partialResult + row.exerciseStatuses.filter(\.isPersonalRecord).count
        }
        let totalVolume = rows.reduce(Float.zero) { partialResult, row in
            partialResult + row.totalVolume
        }
        
        monthSummary = ReportsMonthSummary(monthTitle: Self.monthTitle(for: selectedMonth, calendar: calendar),
                                           workoutCountValueText: "\(rows.count)",
                                           workoutCountTitleText: rows.count == 1 ? "Workout Completed" : "Workouts Completed",
                                           personalRecordValueText: "\(personalRecordCount)",
                                           personalRecordTitleText: personalRecordCount == 1 ? "Personal Record" : "Personal Records",
                                           totalVolumeValueText: unitFormatter.weightTextWithUnit(kilograms: totalVolume),
                                           totalVolumeTitleText: "Total Volume")
        workoutReportCards = rows.map(makeWorkoutReportCardItem)
    }
    
    private func makeWorkoutReportCardItem(from row: ReportDashboardPreparedRow) -> WorkoutReportCardItem {
        WorkoutReportCardItem(id: row.report.id,
                              report: row.report.reportModel,
                              title: row.report.titleWorkout,
                              groupTitle: row.report.titleWorkoutGroup,
                              dateText: formatDate(row.report.startDate),
                              timeText: formatTime(row.report.startDate, endDate: row.report.endDate),
                              status: row.workoutStatus)
    }
    
    private func makeAvailableYears(from rows: [ReportDashboardPreparedRow]) -> [Int] {
        let currentYear = calendar.component(.year, from: Date())
        let years = rows.compactMap { row in
            row.report.startDate.map { calendar.component(.year, from: $0) }
        }
        let minimumYear = min(years.min() ?? currentYear, currentYear)
        let maximumYear = max(years.max() ?? currentYear, currentYear + 1)
        return Array(minimumYear...maximumYear)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "Date unavailable" }
        return date.formatted(date: .complete, time: .omitted)
    }
    
    private func formatTime(_ startDate: Date?, endDate: Date?) -> String {
        guard let startDate, let endDate else { return "Time unavailable" }
        return "\(startDate.formatted(date: .omitted, time: .shortened)) – \(endDate.formatted(date: .omitted, time: .shortened)) • \(formatDuration(endDate.timeIntervalSince(startDate)))"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let safeDuration = max(duration, 0)
        guard safeDuration >= 600 else {
            return safeDuration.timeForDisplay
        }
        
        let minutes = Int((safeDuration / 60).rounded())
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return remainingMinutes > 0 ? "\(hours) hr \(remainingMinutes) min" : "\(hours) hr"
        }
        return "\(minutes) min"
    }
    
    private func formatVolume(_ volume: Float) -> String {
        let roundedVolume = NSNumber(value: Int(volume.rounded()))
        return volumeFormatter.string(from: roundedVolume) ?? "\(Int(volume.rounded()))"
    }
    
    private static func monthTitle(for date: Date, calendar: Calendar) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
