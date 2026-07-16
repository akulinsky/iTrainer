//
//  HiddenExercisesView.swift
//  iTrainer
//
//  Created by Codex on 07.07.2026.
//

import SwiftUI

struct HiddenExercisesView: View {
    let exercises: [ExerciseModel]
    let onRestore: (ExerciseModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(exercises) { exercise in
                    HiddenExerciseCell(model: exercise) {
                        onRestore(exercise)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppColor.backgroundPrimary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.backgroundPrimary)
            .navigationTitle("exercise_list.hidden.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HiddenExercisesView(exercises: [ExerciseModel(title: "Bench Press", typeId: "chest_bench_press")],
                        onRestore: { _ in })
}
