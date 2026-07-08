//
//  ReportExerciseHistoryViewModel.swift
//  iTrainer
//
//  Created by Codex on 08.07.2026.
//

import Foundation

final class ReportExerciseHistoryViewModel: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var historyGroups = [ReportExerciseViewModel.HistoryGroup]()
    @Published private(set) var errorMessage: String?
    
    let title: String
    let subtitle: String
    private let reportExercise: ReportExerciseModel
    private var hasLoadedHistory = false
    
    init(reportExercise: ReportExerciseModel) {
        self.reportExercise = reportExercise
        self.title = reportExercise.titleExercise
        self.subtitle = [reportExercise.titleWorkout, reportExercise.titleWorkoutGroup]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")
    }
    
    func reloadData(force: Bool = false) async {
        let shouldLoad = await MainActor.run {
            guard force || !hasLoadedHistory else { return false }
            isLoading = true
            errorMessage = nil
            return true
        }
        guard shouldLoad else { return }
        
        // Keep the loading state visible long enough for the spinner animation to start.
        try? await Task.sleep(for: .seconds(1))
        
        let currentReport = reportExercise
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let history = await dataManager.fetchReportExercises(exerciseId: currentReport.exerciseId)
            .map { ReportExerciseModel(model: $0) }
        let previousReports = ReportExerciseHistoryBuilder.previousLocalReports(in: history, current: currentReport)
        let groups = ReportExerciseHistoryBuilder.historyGroups(from: previousReports)
        
        await MainActor.run {
            historyGroups = groups
            hasLoadedHistory = true
            isLoading = false
        }
    }
}
