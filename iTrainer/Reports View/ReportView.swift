//
//  ReportView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 19.09.2024.
//

import SwiftUI

struct ReportView: View {
    
    @StateObject var viewModel: ReportViewModel
    
    @Environment(\.navigation) private var navigationManager
    
    @State private var isDeleteReportAlertPresented = false
    
    private let horizontalPadding: CGFloat = 20
    private let onClose: (() -> Void)?
    private let onDelete: (() -> Void)?
    
    init(viewModel: ReportViewModel,
         onClose: (() -> Void)? = nil,
         onDelete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onClose = onClose
        self.onDelete = onDelete
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else {
                reportContent
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("reports.workout_report.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("reports.common.close"))
                }
            }
        }
        .task {
            viewModel.reloadData()
        }
        .alert(Text("reports.workout_report.delete_alert.title"), isPresented: $isDeleteReportAlertPresented) {
            Button("reports.common.cancel", role: .cancel) {}
            Button("reports.common.delete", role: .destructive) {
                deleteReport()
            }
        } message: {
            Text("reports.workout_report.delete_alert.message")
        }
    }
    
    private var reportContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                reportBanner
                summaryGrid
                reportExercisesSection
                deleteReportButton
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 14) {
            LoadingSpinnerView(color: AppColor.brandPrimary,
                               size: 54,
                               lineWidth: 5)
            Text("reports.workout_report.loading")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.titleWorkout)
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            
            Text(viewModel.titleWorkoutGroup)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            
            VStack(alignment: .leading, spacing: 10) {
                headerInfoRow(systemImage: "calendar", text: viewModel.reportDate)
                headerInfoRow(systemImage: "clock", text: "\(viewModel.reportRangeTime)  •  \(viewModel.workoutTime)")
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private func headerInfoRow(systemImage: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 22)
            
            Text(text)
                .font(AppFont.rowSubtitle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(AppColor.textSecondary)
    }
    
    @ViewBuilder
    private var reportBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: viewModel.workoutStatus.systemImage)
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 34)
            
            Text(viewModel.workoutStatus.title)
                .font(AppFont.workoutWidgetTitle)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            
            Spacer(minLength: 0)
        }
        .foregroundStyle(bannerColor)
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bannerColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(bannerColor.opacity(0.35), lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(viewModel.summaryCards) { card in
                summaryCard(card)
            }
        }
    }
    
    @ViewBuilder
    private func summaryCard(_ card: ReportViewModel.SummaryCard) -> some View {
        VStack(spacing: 12) {
            Text(card.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
            
            if let progress = card.progress {
                CircularProgressView(lineWidth: 6,
                                     progress: progress,
                                     trackColor: AppColor.progressTrack,
                                     progressColor: progressColor(for: card))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Text(card.value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .minimumScaleFactor(0.75)
                    }
            } else if let systemImage = card.systemImage {
                VStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(AppColor.textSecondary)
                    
                    Text(card.value)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(height: 72)
            }
            
            Text(card.detail)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 174)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            if let info = card.info {
                MetricInfoButton(info: info, size: 28, iconSize: 16)
                    .padding(.top, 2)
                    .padding(.trailing, 2)
            }
        }
    }
    
    @ViewBuilder
    private var reportExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("reports.workout_report.exercises")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                ForEach(viewModel.exerciseSummaries) { summary in
                    if summary.model.isSupersetItem {
                        ReportExerciseCell(model: summary.model,
                                           status: summary.status,
                                           childStatusById: viewModel.exerciseStatusById) { child in
                            navigationManager.path.append(ReportsRoute.reportExerciseView(item: child))
                        }
                    } else {
                        Button {
                            navigationManager.path.append(ReportsRoute.reportExerciseView(item: summary.model))
                        } label: {
                            ReportExerciseCell(model: summary.model, status: summary.status)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var deleteReportButton: some View {
        Button(role: .destructive) {
            isDeleteReportAlertPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("reports.workout_report.delete_button")
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(AppColor.progressRed)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColor.progressRed.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColor.progressRed.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
    
    private var bannerColor: Color {
        viewModel.workoutStatus.color
    }
    
    private func deleteReport() {
        viewModel.deleteReport {
            onDelete?()
        }
    }
    
    private func progressColor(for card: ReportViewModel.SummaryCard) -> Color {
        guard let progress = card.colorProgress else {
            return AppColor.progressGreen
        }
        
        if progress >= 1 {
            return AppColor.progressGreen
        }
        
        if progress >= 0.5 {
            return AppColor.progressAmber
        }
        
        return AppColor.progressRed
    }
}

#Preview {
    ReportView(viewModel: ReportViewModel(report: ReportWorkoutModel(id: UUID(),
                                                                     titleWorkout: "My Workout",
                                                                     workoutId: UUID(),
                                                                     titleWorkoutGroup: "My Workout Group",
                                                                     workoutGroupId: UUID(),
                                                                     startDate: .now - TimeInterval(3600*2),
                                                                     endDate: .now - TimeInterval(3600))))
}
