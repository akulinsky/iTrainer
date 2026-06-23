//
//  ExerciseTypeListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 13.08.2024.
//

import SwiftUI
import UIKit

struct ExerciseTypeListView: View {
    
    @StateObject var viewModel: ExerciseTypeViewModel
    
//    @State private var editMode = EditMode.inactive
//    @Environment(\.isSearching) var isSearching
    
    @State private var searchText = ""
    
    init(viewModel: ExerciseTypeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        if viewModel.searchQuery.isEmpty {
            content
                .searchable(text: $viewModel.searchQueryExercise, prompt: "Search for exercise")
        } else {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        
        VStack {
            List {
                ForEach(viewModel.exercises) { item in
                    cells(for: item)
                }
                .listRowInsets(EdgeInsets.init(top: 2, leading: 0,
                                               bottom: 2, trailing: 0))
            }
            .navigationTitle(viewModel.categoryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.reloadExercises()
            }
            
            if viewModel.mode == .selecting {
                SelectExerciseBarView(countSelectedExercises: $viewModel.countSelectedExercises) {
                    viewModel.addExercise()
                    
                } clearBlock: {
                    viewModel.clearSelectedExercise()
                }
            }
        }
    }
    
    
    private func cells(for item: ExerciseTypeModel) -> some View {
        NavigationLink {
            exerciseInfo(for: item)
        } label: {
            ExerciseTypeCell(model: item, 
                             mode: viewModel.mode,
                             isSelected: viewModel.isSelectedExercise(with: item.id)) {
                viewModel.toggleSelectExercise(with: item.id)
            }
        }
    }
    
    @ViewBuilder
    private func exerciseInfo(for item: ExerciseTypeModel) -> some View {
        VStack {
            
            if let icon = item.icon {
                icon
                    .resizable()
                    .scaledToFit()
            }
            
            Text("For \(item.title) additional information.")
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    ExerciseTypeListView(viewModel: ExerciseTypeViewModel())
}
