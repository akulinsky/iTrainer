//
//  ReportsCalendarViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import Foundation

@MainActor
final class ReportsCalendarViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var reportCards = [WorkoutReportCardItem]()
    @Published private(set) var calendarMarkers = [Date: CalendarDateMarker]()
    @Published private(set) var minimumMonth = Date()
    @Published private(set) var maximumMonth = Date()
    @Published private(set) var isLoading = false
    @Published var isShowAlert = false
    @Published var selectedDate = Date() {
        didSet {
            let normalizedDate = calendar.startOfDay(for: selectedDate)
            guard selectedDate == normalizedDate else {
                selectedDate = normalizedDate
                return
            }
            applySelectedDate()
        }
    }
    @Published var visibleMonth = Date() {
        didSet {
            let normalizedMonth = calendar.calendarControlStartOfMonth(for: visibleMonth)
            guard visibleMonth == normalizedMonth else {
                visibleMonth = normalizedMonth
                return
            }
        }
    }
    
    var errorMessage: String? = nil
    
    private var preparedRows = [ReportDashboardPreparedRow]()
    private var hasLoadedReports = false
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
        let today = calendar.startOfDay(for: Date())
        self.selectedDate = today
        self.visibleMonth = calendar.calendarControlStartOfMonth(for: today)
        self.minimumMonth = calendar.calendarControlStartOfMonth(for: today)
        self.maximumMonth = calendar.calendarControlStartOfMonth(for: today)
    }
    
    // MARK: - Public Methods
    
    func reloadData(force: Bool = false, complete: (() -> Void)? = nil) {
        Task {
            await reloadData(force: force)
            complete?()
        }
    }
    
    func reloadData(force: Bool = false) async {
        guard force || !hasLoadedReports else {
            applySelectedDate()
            return
        }
        
        isLoading = true
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let snapshots = await dataManager.fetchCompletedReportDashboardSnapshots()
        let rows = await Task.detached(priority: .userInitiated) {
            ReportDashboardDataBuilder().buildRows(from: snapshots)
        }.value
        
        preparedRows = rows
        hasLoadedReports = true
        rebuildCalendarState()
        applySelectedDate()
        isLoading = false
    }
    
    func refreshData() {
        reloadData(force: true)
    }
    
    // MARK: - Private Methods
    
    private func rebuildCalendarState() {
        maximumMonth = calendar.calendarControlStartOfMonth(for: Date())
        minimumMonth = firstReportMonth() ?? maximumMonth
        visibleMonth = calendar.calendarControlClampedMonth(visibleMonth,
                                             minimumMonth: minimumMonth,
                                             maximumMonth: maximumMonth)
        selectedDate = calendar.calendarControlDate(in: visibleMonth, matchingDayFrom: selectedDate)
        calendarMarkers = buildCalendarMarkers()
    }
    
    private func firstReportMonth() -> Date? {
        preparedRows
            .compactMap { $0.report.startDate }
            .min()
            .map { calendar.calendarControlStartOfMonth(for: $0) }
    }
    
    private func buildCalendarMarkers() -> [Date: CalendarDateMarker] {
        let datedMarkers = preparedRows.compactMap { row -> (date: Date, marker: CalendarDateMarker)? in
            guard let startDate = row.report.startDate else { return nil }
            return (calendar.startOfDay(for: startDate), marker(for: row))
        }
        let groupedMarkers = Dictionary(grouping: datedMarkers, by: \.date).mapValues { values in
            values.map(\.marker)
        }
        
        return groupedMarkers.compactMapValues(CalendarDateMarker.merged)
    }
    
    private func marker(for row: ReportDashboardPreparedRow) -> CalendarDateMarker {
        if case .personalRecord = row.workoutStatus {
            return .personalRecord
        }
        return .workout
    }
    
    private func applySelectedDate() {
        reportCards = preparedRows
            .filter { row in
                guard let startDate = row.report.startDate else { return false }
                return calendar.isDate(startDate, inSameDayAs: selectedDate)
            }
            .sorted { ($0.report.startDate ?? .distantPast) > ($1.report.startDate ?? .distantPast) }
            .map(makeWorkoutReportCardItem)
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
}
