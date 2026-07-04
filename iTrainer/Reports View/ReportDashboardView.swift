//
//  ReportDashboardView.swift
//  iTrainer
//
//  Created by Codex on 03.07.2026.
//

import SwiftUI

enum ReportsRoute: Hashable {
    case reportsView
    case reportView(item: ReportWorkoutModel)
    case reportExerciseView(item: ReportExerciseModel)
    case exerciseStatisticsView(item: ReportExerciseModel)
}

struct ReportDashboardView: View {
    
    @StateObject private var viewModel = ReportDashboardViewModel()
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryHeader
                    metricsGrid
                    latestReportSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationManager.path.append(ReportsRoute.reportsView)
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }
            }
            .navigationDestination(for: ReportsRoute.self, destination: destination)
            .task {
                await viewModel.reloadReports()
            }
        }
        .environment(\.navigation, navigationManager)
    }
    
    @ViewBuilder
    private func destination(for route: ReportsRoute) -> some View {
        switch route {
        case .reportsView:
            ReportsView()
                .environment(\.navigation, navigationManager)
        case .reportView(let report):
            ReportView(viewModel: ReportViewModel(report: report), onDelete: closeDeletedReport)
                .environment(\.navigation, navigationManager)
        case .reportExerciseView(let exercise):
            ReportExerciseView(viewModel: ReportExerciseViewModel(reportExercise: exercise))
                .environment(\.navigation, navigationManager)
        case .exerciseStatisticsView(let exercise):
            ExerciseStatisticsView(exercise: exercise)
        }
    }
    
    private func closeDeletedReport() {
        if !navigationManager.path.isEmpty {
            navigationManager.path.removeLast()
        }
        Task {
            await viewModel.reloadReports()
        }
    }
    
    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dashboard")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColor.textPrimary)
            Text(viewModel.latestReportDateText)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            dashboardMetric(
                title: "Reports",
                value: "\(viewModel.completedReportsCount)",
                systemImage: "doc.text",
                color: AppColor.brandPrimary
            )
            dashboardMetric(
                title: "Exercises",
                value: "\(viewModel.totalExercisesCount)",
                systemImage: "figure.strengthtraining.traditional",
                color: AppColor.workoutGreen
            )
        }
    }
    
    private var latestReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Report")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 88)
            } else if let latestReport = viewModel.latestReport {
                latestReportCard(latestReport)
            } else {
                emptyLatestReportCard
            }
        }
    }
    
    private func dashboardMetric(title: String, value: String, systemImage: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppColor.textPrimary)
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private func latestReportCard(_ report: ReportWorkoutModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(report.titleWorkout)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(viewModel.reportTimeText(report))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Text(report.titleWorkoutGroup)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private var emptyLatestReportCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No completed reports")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("History will appear after a completed workout.")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    ReportDashboardView()
}
