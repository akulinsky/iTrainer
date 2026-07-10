//
//  ExerciseTypeView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import SwiftUI

enum ExerciseTypeRoute: Hashable {
    case exerciseTypeListView(categoryId: String)
    case exerciseDetailView(exerciseId: String)
    case exerciseStatisticsView(exerciseId: String)
}

struct ExerciseTypeView: View {
    
    @StateObject var viewModel: ExerciseTypeViewModel
    
//    @Environment(\.isSearching) private var isSearching
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @StateObject private var navigationManager = NavigationManager()
    @State private var isCreateCustomExercisePresented = false
    @State private var pendingCreatedExerciseId: String?
    
    let mode: ExerciseTypeViewMode
    
    var bbb = false
    
    init(mode: ExerciseTypeViewMode = .showing, completeBlock: (SelectedExerciseTypesBlock)? = nil) {
        
        //_viewModel = StateObject(wrappedValue: viewModel)/
        
        self.mode = mode
        _viewModel = StateObject(wrappedValue: ExerciseTypeViewModel(mode: mode, completeBlock: completeBlock))
//        _viewModel =  StateObject(wrappedValue: ExerciseTypeViewModel(mode: .selecting))
    }
    
//    @State private var rotationDegrees = 0.0
//    private var animation: Animation {
//        .linear
//        .speed(0.1)
//        .repeatForever(autoreverses: false)
//    }
    
    var body: some View {
        
        // Animation
//        Image(systemName: "gear")
//            .font(.system(size: 186))
//            .rotationEffect(.degrees(rotationDegrees))
//            .onAppear {
//                withAnimation(animation) {
//                    rotationDegrees = 360.0
//                }
//            }
        
        NavigationStack(path: $navigationManager.path) {
            VStack {
                if viewModel.showsFlatExerciseList {
                    ExerciseTypeListView(viewModel: viewModel)
                } else {
                    ExerciseCategoryView(viewModel: viewModel)
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchQuery, prompt: "Search for exercise")
            .tint(AppColor.brandPrimary)
            .toolbar {
                if mode == .showing && !presentationMode.wrappedValue.isPresented {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isCreateCustomExercisePresented = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Create Exercise")
                    }
                }
                
                if presentationMode.wrappedValue.isPresented {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            cancel()
                        }
                    }
                }

            }
            .sheet(isPresented: $isCreateCustomExercisePresented) {
                CreateCustomExerciseView { newExerciseId in
                    pendingCreatedExerciseId = newExerciseId
                }
            }
            .onChange(of: isCreateCustomExercisePresented) { _, isPresented in
                guard !isPresented, let pendingCreatedExerciseId else { return }
                self.pendingCreatedExerciseId = nil
                viewModel.reloadExercises()
                navigationManager.path.append(ExerciseTypeRoute.exerciseDetailView(exerciseId: pendingCreatedExerciseId))
            }
            .onChange(of: navigationManager.path) { _, path in
                guard path.isEmpty else { return }
                viewModel.categoryId = nil
                viewModel.reloadExercises()
            }
            .contentSelf(content: { view in
                contentViewNavigation(content: view)
            })
        }
        .environment(\.navigation, navigationManager)
    }
    
    @ViewBuilder
    private func contentViewNavigation<T: View>(content: T) -> some View {
        content
            .navigationDestination(for: ExerciseTypeRoute.self) { item in
                switch item {
                case .exerciseTypeListView(let categoryId):
                    ExerciseTypeListView(viewModel: viewModel)
                        .onAppear {
                            viewModel.categoryId = categoryId
                            viewModel.reloadExercises()
                        }
                case .exerciseDetailView(let exerciseId):
                    if let exercise = viewModel.exercise(with: exerciseId) {
                        ExerciseCatalogDetailView(model: exercise,
                                                  onOpenStatistics: {
                                                    navigationManager.path.append(ExerciseTypeRoute.exerciseStatisticsView(exerciseId: exercise.id))
                                                  },
                                                  onBookmarkChanged: { _ in
                                                    viewModel.reloadExercises()
                                                  },
                                                  onDelete: {
                                                    viewModel.reloadExercises()
                                                    navigationManager.path = NavigationPath()
                                                  })
                    }
                case .exerciseStatisticsView(let exerciseId):
                    if let exercise = viewModel.exercise(with: exerciseId) {
                        ExerciseStatisticsView(exerciseType: exercise)
                    }
                }
            }
    }
    
    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ExerciseTypeView()
}
