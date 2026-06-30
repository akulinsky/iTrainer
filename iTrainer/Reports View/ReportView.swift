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
    
    private let horizontalPadding: CGFloat = 20
    
    init(viewModel: ReportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                reportBanner
                summaryGrid
                reportExercisesSection
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Workout Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.reloadData()
        }
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
            Image(systemName: viewModel.bannerStyle.systemImage)
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 34)
            
            Text(viewModel.bannerStyle.title)
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
                                     progressColor: AppColor.progressGreen)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Text(card.value)
                            .font(.system(size: 20, weight: .bold))
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
    }
    
    @ViewBuilder
    private var reportExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                ForEach(viewModel.exerciseSummaries) { summary in
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
    
    private var bannerColor: Color {
        switch viewModel.bannerStyle {
        case .personalRecord:
            AppColor.restAmber
        case .progress, .goalsAchieved, .complete:
            AppColor.progressGreen
        case .goalsNotAchieved:
            AppColor.progressRed
        case .workoutIncomplete:
            AppColor.progressAmber
        }
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
