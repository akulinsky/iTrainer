//
//  ExerciseCategoryView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import SwiftUI

struct ExerciseCategoryView: View {
    
    @StateObject var viewModel: ExerciseTypeViewModel
    
    private let frameSize: CGFloat = 80
    
    init(viewModel: ExerciseTypeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        VStack {
            List(selection: $viewModel.categoryId) {
                
                ForEach(viewModel.categories) { item in
                    
                    NavigationLink {
                        ExerciseTypeListView(viewModel: viewModel)
                    } label: {
                        HStack {
                            item.icon
                                .resizable()
                                .frame(width: frameSize)
                            Text(item.title).leadingAlignment()
                        }
                        .frame(height: frameSize)
                    }
                }
                .listRowInsets(EdgeInsets.init(top: 2, leading: 0,
                                               bottom: 2, trailing: 0))
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
