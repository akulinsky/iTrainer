//
//  WorkoutGroupListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct WorkoutGroupListView: View {
    
    @StateObject var viewModel: WorkoutGroupListViewModel
    
    init(viewModel: WorkoutGroupListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.workoutGroups) { item in
                    
                    NavigationLink {
                        ExerciseListView(viewModel: ExerciseListViewModel(group: item))
                    } label: {
                        WorkoutGroupCell(model: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .refreshable {
                refresh()
            }
        }
        .navigationTitle("Groups")
        .task {
            viewModel.reloadData {
                if viewModel.workoutGroups.count == 0 {
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
    WorkoutGroupListView(viewModel: WorkoutGroupListViewModel(workout: WorkoutModel(title: "TEST")))
}
