//
//  ExerciseListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct ExerciseListView: View {
    
    @StateObject var viewModel: ExerciseListViewModel
    
    init(viewModel: ExerciseListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.exercises) { item in
                    
                    NavigationLink {
                        ExerciseView(viewModel: ExerciseViewModel(exercise: item))
                    } label: {
                        ExerciseCell(model: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .refreshable {
                refresh()
            }
        }
        .navigationTitle("Exercises")
        .task {
            viewModel.reloadData {
                if viewModel.exercises.count == 0 {
                    refresh()
                }
            }
        }
    }
    
    private func refresh() {
        viewModel.refreshData()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
//            for index in offsets {
//                viewModel.delete(index: index)
//            }
        }
    }
}

#Preview {
    ExerciseListView(viewModel: ExerciseListViewModel(group: WorkoutGroupModel(title: "TEST")))
}
