//
//  ReportDashboardViewModel.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import Foundation

struct ReportsMonthSummary: Hashable {
    let monthTitle: String
    let workoutCountText: String
    let personalRecordCountText: String
    let totalVolumeText: String
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
    
    private var allReportRows = [DashboardReportRow]()
    private let calendar: Calendar
    private let volumeFormatter: NumberFormatter
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.selectedMonth = calendar.startOfMonth(for: Date())
        self.monthSummary = ReportsMonthSummary(monthTitle: Self.monthTitle(for: Date(), calendar: calendar),
                                                workoutCountText: "0 Workouts Completed",
                                                personalRecordCountText: "0 Personal Records",
                                                totalVolumeText: "0 kg Total Volume")
        self.availableYears = [calendar.component(.year, from: Date())]
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        self.volumeFormatter = formatter
    }
    
    func reloadReports() async {
        isLoading = true
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let reportModels = await dataManager.fetchAllReportWorkout()
            .filter { $0.endDate != nil }
        let reportRows = reportModels.map { reportModel in
            let report = ReportWorkoutModel(model: reportModel)
            let exercises = reportModel.exercises
                .map { ReportExerciseModel(model: $0) }
                .sorted { $0.index < $1.index }
            return DashboardReportRow(report: report,
                                      exercises: exercises,
                                      exerciseStatuses: [],
                                      workoutStatus: .workoutComplete)
        }
        let exerciseHistoryByType = Dictionary(grouping: reportRows.flatMap(\.exercises), by: \.typeId)
        
        allReportRows = reportRows.map { row in
            let exerciseStatuses = row.exercises.map { exercise in
                ReportStatusService.calculateExerciseStatus(report: exercise,
                                                            history: exerciseHistoryByType[exercise.typeId] ?? [])
            }
            let workoutStatus = ReportStatusService.calculateWorkoutStatus(report: row.report,
                                                                           exercises: row.exercises,
                                                                           exerciseStatuses: exerciseStatuses)
            return DashboardReportRow(report: row.report,
                                      exercises: row.exercises,
                                      exerciseStatuses: exerciseStatuses,
                                      workoutStatus: workoutStatus)
        }
        availableYears = makeAvailableYears(from: allReportRows)
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
        let rows = allReportRows
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
            partialResult + ReportStatusService.totalVolume(for: row.exercises)
        }
        
        monthSummary = ReportsMonthSummary(monthTitle: Self.monthTitle(for: selectedMonth, calendar: calendar),
                                           workoutCountText: "\(rows.count) \(rows.count == 1 ? "Workout" : "Workouts") Completed",
                                           personalRecordCountText: "\(personalRecordCount) \(personalRecordCount == 1 ? "Personal Record" : "Personal Records")",
                                           totalVolumeText: "\(formatVolume(totalVolume)) kg Total Volume")
        workoutReportCards = rows.map(makeWorkoutReportCardItem)
    }
    
    private func makeWorkoutReportCardItem(from row: DashboardReportRow) -> WorkoutReportCardItem {
        WorkoutReportCardItem(id: row.report.id,
                              report: row.report,
                              title: row.report.titleWorkout,
                              groupTitle: row.report.titleWorkoutGroup,
                              dateText: formatDate(row.report.startDate),
                              timeText: formatTime(row.report.startDate, endDate: row.report.endDate),
                              status: row.workoutStatus)
    }
    
    private func makeAvailableYears(from rows: [DashboardReportRow]) -> [Int] {
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

private struct DashboardReportRow {
    let report: ReportWorkoutModel
    let exercises: [ReportExerciseModel]
    let exerciseStatuses: [ExerciseReportStatus]
    let workoutStatus: WorkoutReportStatus
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
