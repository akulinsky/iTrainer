//
//  ReportsView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import SwiftUI

struct ReportsView: View {
    
    @StateObject var viewModel = ReportsViewModel()
    @Environment(\.navigation) private var navigationManager
    
    var body: some View {
        VStack(spacing: 0) {
            calendar
            reportsList
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .task {
            await viewModel.reloadData()
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var calendar: some View {
        DatePicker("", selection: $viewModel.selectedDate,
                   displayedComponents: [.date])
            .datePickerStyle(.graphical)
            .padding(.horizontal, 12)
            .background(AppColor.surfacePrimary)
    }
    
    @ViewBuilder
    private var reportsList: some View {
        List {
            if viewModel.isLoading && viewModel.reportCards.isEmpty {
                loadingRow
            } else if viewModel.reportCards.isEmpty {
                emptyRow
            } else {
                ForEach(viewModel.reportCards) { item in
                    WorkoutReportCard(item: item) {
                        navigationManager.path.append(ReportsRoute.reportView(item: item.report))
                    }
                    .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppColor.backgroundPrimary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .refreshable {
            viewModel.refreshData()
        }
    }
    
    private var loadingRow: some View {
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
        .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
        .listRowSeparator(.hidden)
        .listRowBackground(AppColor.backgroundPrimary)
    }
    
    private var emptyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No reports for this day")
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
        .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
        .listRowSeparator(.hidden)
        .listRowBackground(AppColor.backgroundPrimary)
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
}
