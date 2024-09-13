//
//  ExerciseTypeView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import SwiftUI

struct ExerciseTypeView: View {
    
    @StateObject var viewModel: ExerciseTypeViewModel
    
//    @Environment(\.isSearching) private var isSearching
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
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
        
        
        NavigationStack {
            
            VStack {
                if viewModel.searchQuery.isEmpty {
                    MuscleTypeView(viewModel: viewModel)
                } else {
                    ExerciseTypeListView(viewModel: viewModel)
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $viewModel.searchQuery, prompt: "Search for exercise")
            .toolbar {
                if presentationMode.wrappedValue.isPresented {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            cancel()
                        }
                    }
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
