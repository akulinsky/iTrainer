//
//  ReportsViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import Foundation

@MainActor
final class ReportsViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var reportCards = [WorkoutReportCardItem]()
    @Published private(set) var isLoading = false
    @Published var isShowAlert = false
    @Published var selectedDate = Date() {
        didSet {
            applySelectedDate()
        }
    }
    
    var errorMessage: String? = nil
    
    private var preparedRows = [ReportDashboardPreparedRow]()
    private var hasLoadedReports = false
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
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
        applySelectedDate()
        isLoading = false
    }
    
    func refreshData() {
        reloadData(force: true)
    }
    
    // MARK: - Private Methods
    
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
