//
//  ReportExerciseHistoryView.swift
//  iTrainer
//
//  Created by Codex on 08.07.2026.
//

import SwiftUI

struct ReportExerciseHistoryView: View {
    @StateObject var viewModel: ReportExerciseHistoryViewModel
    
    private let horizontalPadding: CGFloat = 20
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.historyGroups.isEmpty {
                emptyStateView
            } else {
                historyContent
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("reports.history.screen_title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.reloadData()
        }
    }
    
    private var historyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                ReportExerciseHistorySection(groups: viewModel.historyGroups)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            
            if !viewModel.subtitle.isEmpty {
                Text(viewModel.subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 14) {
            LoadingSpinnerView(color: AppColor.brandPrimary,
                               size: 54,
                               lineWidth: 5)
                Text("reports.history.loading")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                Text("reports.history.empty.title")
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.textPrimary)
                Text("reports.history.empty.subtitle")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
