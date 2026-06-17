//
//  ReportsView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import SwiftUI

struct ReportsView: View {
    
    @StateObject var viewModel = ReportsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                calendar
                reportsList
            }
            .task {
                viewModel.reloadData()
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
        }
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
                
                NavigationLink {
                    ReportView(viewModel: ReportViewModel(report: item))
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
                }
            }
        }
    }
}

#Preview {
    ReportsView()
}
