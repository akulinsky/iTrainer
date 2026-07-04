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
    
    private let horizontalPadding: CGFloat = 20
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ReportsDashboardHeaderView(summary: viewModel.monthSummary,
                                               action: viewModel.showMonthPicker)
                    workoutsSection
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationManager.path.append(ReportsRoute.reportsView)
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                    }
                    .accessibilityLabel("History")
                }
            }
            .navigationDestination(for: ReportsRoute.self, destination: destination)
            .sheet(isPresented: $viewModel.isMonthPickerPresented) {
                MonthPickerSheet(selectedMonth: viewModel.selectedMonth,
                                 availableYears: viewModel.availableYears,
                                 onCancel: {
                                    viewModel.isMonthPickerPresented = false
                                 },
                                 onSelect: { month in
                                    viewModel.selectMonth(month)
                                    viewModel.isMonthPickerPresented = false
                                 })
                    .presentationDetents([.height(320)])
            }
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
    
    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Workouts")
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.brandPrimary)
            
            if viewModel.isLoading && viewModel.workoutReportCards.isEmpty {
                loadingCard
            } else if viewModel.workoutReportCards.isEmpty {
                emptyStateCard
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.workoutReportCards) { item in
                        WorkoutReportCard(item: item) {
                            navigationManager.path.append(ReportsRoute.reportView(item: item.report))
                        }
                    }
                }
            }
        }
    }
    
    private var loadingCard: some View {
        VStack(spacing: 14) {
            LoadingSpinnerView(color: AppColor.brandPrimary,
                               size: 44,
                               lineWidth: 4)
            Text("Loading reports")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No workouts this month")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("Completed workouts will appear here.")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private func closeDeletedReport() {
        if !navigationManager.path.isEmpty {
            navigationManager.path.removeLast()
        }
        Task {
            await viewModel.reloadReports(force: true)
        }
    }
}

#Preview {
    ReportDashboardView()
}
