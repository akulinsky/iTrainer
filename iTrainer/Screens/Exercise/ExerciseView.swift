//
//  ExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct ExerciseView: View {
    
    @StateObject var viewModel: ExerciseViewModel
    
    init(viewModel: ExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        VStack {
            Text("Hello, World!")
                .frame(height: 100)
            List {
                ForEach(viewModel.sets) { item in
                    
//                    NavigationLink {
//                        ExerciseView()
//                    } label: {
//                        ExerciseCell(model: item)
//                    }
                    SetsCell(model: item)
                }
                .onDelete(perform: deleteItems)
            }
            .refreshable {
                refresh()
            }
        }
        .navigationTitle(viewModel.exercise.title ?? "Exercise")
        .task {
            viewModel.reloadData {
                if viewModel.sets.count == 0 {
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
            for index in offsets {
                viewModel.delete(index: index)
            }
        }
    }
}

#Preview {
    ExerciseView(viewModel: ExerciseViewModel(exercise: ExerciseModel(title: "fff")))
}
