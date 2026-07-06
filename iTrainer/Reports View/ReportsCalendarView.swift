//
//  ReportsCalendarView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import SwiftUI

struct ReportsCalendarView: View {
    
    @StateObject var viewModel = ReportsCalendarViewModel()
    @Environment(\.navigation) private var navigationManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                CalendarView(selectedDate: $viewModel.selectedDate,
                             visibleMonth: $viewModel.visibleMonth,
                             markers: viewModel.calendarMarkers,
                             minimumMonth: viewModel.minimumMonth,
                             maximumMonth: viewModel.maximumMonth)
                selectedDateSection
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .refreshable {
            viewModel.refreshData()
        }
        .task {
            await viewModel.reloadData()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.selectedDate.formatted(.dateTime.month(.wide).day().year()))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            if viewModel.isLoading && viewModel.reportCards.isEmpty {
                loadingCard
            } else if viewModel.reportCards.isEmpty {
                emptyStateCard
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.reportCards) { item in
                        WorkoutReportCard(item: item) {
                            navigationManager.path.append(ReportsRoute.reportView(item: item.report))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColor.separatorSoft)
                .frame(height: 1)
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
            Text("No workouts on this date")
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
}

#Preview {
    NavigationStack {
        ReportsCalendarView()
    }
}
