//
//  ExerciseCategoryView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import SwiftUI

struct ExerciseCategoryView: View {
    
    @StateObject var viewModel: ExerciseTypeViewModel
    
//    @Environment(\.isSearching) var isSearching
    
    init(viewModel: ExerciseTypeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        VStack {
            List(selection: $viewModel.categoryId) {
                
    //            Section {
    //                ForEach(viewModel.categories) { item in
    //
    //                    NavigationLink {
    //                        ExerciseTypeListView(viewModel: viewModel)
    //                    } label: {
    //                        HStack {
    //                            item.icon
    //                                .resizable()
    //                                .frame(width: 60)
    //                            Text(item.title).leadingAlignment()
    //                        }
    //                        .frame(height: 60)
    //                    }
    //                }
    //            } header: {
    //                if viewModel.mode == .selecting {
    //                    Text("Selected: \(viewModel.countSelectedExercises)")
    //                        .bold()
    //                }
    //            }
                
                ForEach(viewModel.categories) { item in
                    
                    NavigationLink {
                        ExerciseTypeListView(viewModel: viewModel)
                    } label: {
                        HStack {
                            item.icon
                                .resizable()
                                .frame(width: 60)
                            Text(item.title).leadingAlignment()
                        }
                        .frame(height: 60)
                    }
                }
            }
            
            if viewModel.mode == .selecting {
                SelectExerciseBarView(countSelectedExercises: $viewModel.countSelectedExercises) {
                    viewModel.addExercise()
                    
                } clearBlock: {
                    viewModel.clearSelectedExercise()
                }
            }
        }
        .onAppear {
            viewModel.categoryId = nil
        }
    }
}

#Preview {
    ExerciseCategoryView(viewModel: ExerciseTypeViewModel())
}
