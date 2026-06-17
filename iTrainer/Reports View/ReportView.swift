//
//  ReportView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 19.09.2024.
//

import SwiftUI

struct ReportView: View {
    
    @StateObject var viewModel: ReportViewModel
    
    init(viewModel: ReportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                
                VStack {
                    logo
                    reportDate
                        .padding([.top], 10)
                    reportTitle
//                    timeWorkout
                    reportProgress
                }
                .listRowInsets(EdgeInsets.init(top: 0, leading: 0,
                                            bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .padding(.bottom)
                
                reportExercisesView
                
                Spacer(minLength: 20)
//                    .padding(.top)
//                    .listRowInsets(EdgeInsets.init(top: 0, leading: 10,
//                                                    bottom: 0, trailing: 10))
            }
            .listStyle(.plain)
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.reloadData()
        }
    }
    
    @ViewBuilder
    private var logo: some View {
        
        Text("iTrainer")
            .font(.largeTitle)
            .foregroundStyle(.white)
            .shadow(color: .black, radius: 1, x: 1.0, y: 1.0)
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(gradient: Gradient(colors: [.blue, .yellow]),
                               startPoint: .top,
                               endPoint: .bottom)
            }
    }
    
    @ViewBuilder
    private var reportDate: some View {
        VStack(spacing: 10) {
            Text(viewModel.reportDate)
            Text(viewModel.reportRangeTime)
                .font(.callout)
        }
    }
    
    @ViewBuilder
    private var reportTitle: some View {
        
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.titleWorkout)
                    .font(.headline)
                    .bold()
                
                Text(viewModel.titleWorkoutGroup)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Workout time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 10) {
                CircularProgressView(progress: viewModel.progressWorkout)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(viewModel.percentageProgressWorkout)
                            .font(.footnote)
                            .bold()
                    }
                
                Text(viewModel.workoutTime)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .bold()
                    .frame(width: 50)
                    .padding(.top, 8)
            }
        }
        .background {
            Rectangle()
                .stroke(.gray, lineWidth: 1.0)
                .padding(-10)
        }
        .padding(20)
    }
    
//    @ViewBuilder
//    private var timeWorkout: some View {
//        
//        VStack(spacing: 10) {
//            Text("Workout time")
//                .font(.headline)
//                .foregroundStyle(.secondary)
//            Text(viewModel.workoutTime)
//                .font(.title3)
//                .bold()
//        }
//        .frame(maxWidth: .infinity)
//        .background {
//            Rectangle()
//                .stroke(.gray, lineWidth: 1.0)
//                .padding(-10)
//        }
//        .padding([.leading, .trailing], 20)
//        .padding([.top, .bottom], 10)
//    }
    
    @ViewBuilder
    private var reportProgress: some View {
        
        VStack(spacing: 10) {
            ForEach(viewModel.reportModels) { model in
                reportCell(model: model)
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .stroke(.gray, lineWidth: 1.0)
                .padding(-10)
        }
        .padding([.leading, .trailing], 20)
        .padding([.top, .bottom], 10)
    }
    
    @ViewBuilder
    private func reportCell(model: ReportViewModel.ReportModel) -> some View {
        
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(model.primary)
                    .font(.headline)
                    .bold()
                
                Text(model.secondary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 10) {
                CircularProgressView(progress: model.progress)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(model.percentageProgress)
                            .font(.footnote)
                            .bold()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var reportExercisesView: some View {
        ForEach(viewModel.reportExercises) { exercise in
            NavigationLink {
                ReportExerciseView(viewModel: ReportExerciseViewModel(reportExercise: exercise))
            } label: {
                ReportExerciseCell(model: exercise)
            }
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
