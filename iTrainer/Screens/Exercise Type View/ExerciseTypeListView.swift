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
    
    @Environment(\.navigation) private var navigation
    
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
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.exercises) { item in
                    cells(for: item)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
            .background(AppColor.backgroundPrimary)
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
        .background(AppColor.backgroundPrimary)
    }
    
    private func cells(for item: ExerciseTypeModel) -> some View {
        Button {
            navigation.path.append(ExerciseTypeRoute.exerciseDetailView(exerciseId: item.id))
        } label: {
            ExerciseTypeCell(model: item,
                             mode: viewModel.mode,
                             isSelected: viewModel.isSelectedExercise(with: item.id)) {
                viewModel.toggleSelectExercise(with: item.id)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExerciseTypeListView(viewModel: ExerciseTypeViewModel())
}
