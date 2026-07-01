//
//  ExerciseStatisticsView.swift
//  iTrainer
//
//  Created by OpenAI on 01.07.2026.
//

import SwiftUI

struct ExerciseStatisticsView: View {
    let exercise: ReportExerciseModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AppColor.brandPrimary)
            
            Text("Exercise Statistics")
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(exercise.titleExercise)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            
            Text("History, records, and long-term progress will be shown here.")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExerciseStatisticsView(exercise: ReportExerciseModel(titleExercise: "Bench Press",
                                                             exerciseId: UUID(),
                                                             index: 1,
                                                             typeId: "chest_bench_press"))
    }
}
