//
//  ExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct ExerciseView: View {
    
    @StateObject var viewModel: ExerciseViewModel
    
    @State private var editMode = EditMode.inactive
    
    init(viewModel: ExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        VStack {
            Text("Ukraine must win!")
                .font(.largeTitle.bold())
                .frame(height: 100)
                .foregroundStyle(
                    .linearGradient(colors: [.blue, .yellow],
                                    startPoint: .top,
                                    endPoint: .bottom)
                )
            List {
                ForEach(viewModel.sets) { item in
                    SetsCell(model: item) {
                        switch $0 {
                        case .update(let updateModel):
                            viewModel.edit(sets: updateModel)
                            break
                        default:
                            break
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .refreshable {
                refresh()
            }
            .environment(\.editMode, $editMode)
        }
        .navigationTitle(viewModel.exercise.title ?? "Exercise")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                optionButton()
            }
        }
        .task {
            viewModel.reloadData {
                if viewModel.sets.count == 0 {
                    refresh()
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditSets, content: {
            editSets()
                .presentationDetents([.medium])
        })
    }
    
    private func optionButton() -> some View {
        switch editMode {
        case .active:
            return AnyView(Button("Done", action: clickBtnDone).bold())
        default:
            return AnyView(menuItem())
        }
    }
    
    private func menuItem() -> some View {
        Menu {
            Button("Edit", systemImage: "pencil", action: clickBtnEditint)
            Button("New exercise", systemImage: "plus.square", action: clickBtnNewWorkout)
        } label: {
            Image(systemName: "ellipsis")
        }
    }
    
    private func editSets() -> some View {
        
        return EditSetsView(title: viewModel.editSets == nil ? "New sets" : "Edit sets",
                            weight: Float(viewModel.editSets?.weight ?? 0),
                            reps: viewModel.editSets?.reps ?? 0) {
            
            switch $0 {
            case .save(let weight, let reps):
                viewModel.update(weight: weight, reps: reps)
            default:
                break
            }
        }
    }
    
    private func clickBtnEditint() {
        withAnimation {
            editMode = .active
        }
    }
    
    private func clickBtnDone() {
        withAnimation {
            editMode = .inactive
        }
    }
    
    private func clickBtnNewWorkout() {
        viewModel.editSets = nil
        viewModel.isEditSets = true
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
    
    private func moveItems(source: IndexSet, destination: Int) {
        viewModel.moveItem(source: source, destination: destination)
    }
}

#Preview {
    ExerciseView(viewModel: ExerciseViewModel(exercise: ExerciseModel(title: "fff")))
}
