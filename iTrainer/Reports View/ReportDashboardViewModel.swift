//
//  ReportDashboardViewModel.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import Foundation

@MainActor
final class ReportDashboardViewModel: ObservableObject {
    
    @Published private(set) var reports = [ReportWorkoutModel]()
    @Published private(set) var isLoading = false
    
    var latestReport: ReportWorkoutModel? {
        reports
            .filter { $0.endDate != nil }
            .max { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
    }
    
    var completedReportsCount: Int {
        reports.filter { $0.endDate != nil }.count
    }
    
    var totalExercisesCount: Int {
        reports.reduce(0) { $0 + $1.targetExercisesCount }
    }
    
    var latestReportDateText: String {
        guard let startDate = latestReport?.startDate else {
            return "No report history yet"
        }
        return "Last workout: \(startDate.formatted(date: .abbreviated, time: .omitted))"
    }
    
    func reloadReports() async {
        isLoading = true
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let items = await dataManager.fetchAllReportWorkout().map { ReportWorkoutModel(model: $0) }
        reports = items
        isLoading = false
    }
    
    func reportTimeText(_ report: ReportWorkoutModel) -> String {
        guard let start = report.startDate, let end = report.endDate else {
            return ""
        }
        return "\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }
}
