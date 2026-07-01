//
//  ReportsView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import SwiftUI

enum ReportsRoute: Hashable {
    case reportView(item: ReportWorkoutModel)
    case reportExerciseView(item: ReportExerciseModel)
}

struct ReportsView: View {
    
    @StateObject var viewModel = ReportsViewModel()
    
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            VStack {
                calendar
                reportsList
            }
            .task {
                viewModel.reloadData()
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .contentSelf(content: { view in
                contentViewNavigation(content: view)
            })
        }
        .environment(\.navigation, navigationManager)
    }
    
    @ViewBuilder
    private func contentViewNavigation<T: View>(content: T) -> some View {
        content
            .navigationDestination(for: ReportsRoute.self, destination: { route in
                switch route {
                case .reportView(let report):
                    ReportView(viewModel: ReportViewModel(report: report), onDelete: closeDeletedReport)
                        .environment(\.navigation, navigationManager)
                case .reportExerciseView(let exercise):
                    ReportExerciseView(viewModel: ReportExerciseViewModel(reportExercise: exercise))
                        .environment(\.navigation, navigationManager)
                }
            })
    }
    
    @ViewBuilder
    private var calendar: some View {
        DatePicker("", selection: $viewModel.selectedDate,
                   displayedComponents: [.date])
            .datePickerStyle(.graphical)
    }
    
    @ViewBuilder
    private var reportsList: some View {
        List {
            ForEach(viewModel.reports) { item in
                reportRow(for: item)
            }
        }
    }
    
    private func closeDeletedReport() {
        if !navigationManager.path.isEmpty {
            navigationManager.path.removeLast()
        }
        viewModel.reloadData()
    }
    
    private func reportRow(for item: ReportWorkoutModel) -> some View {
        Button {
            navigationManager.path.append(ReportsRoute.reportView(item: item))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(item.titleWorkout)")
                        .font(.headline)
                        .bold()
                    Text("\(item.titleWorkoutGroup)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                if let start = item.startDate, let end = item.endDate {
                    Text("\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReportsView()
}
