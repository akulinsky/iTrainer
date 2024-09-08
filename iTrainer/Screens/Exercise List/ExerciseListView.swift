//
//  ExerciseListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct ExerciseListView: View {
    
    @StateObject var viewModel: ExerciseListViewModel
    
    @State private var editMode = EditMode.inactive
    
    @State private var showAnimation = false
    
    init(viewModel: ExerciseListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.exercises) { item in
                    cells(for: item)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .animation(.easeInOut, value: showAnimation)
            .refreshable {
                refresh()
            }
            .environment(\.editMode, $editMode)
        }
        .environment(\.defaultMinListRowHeight, 10)
        .navigationTitle(viewModel.group.title ?? "Exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                optionButton()
            }
        }
        .task {
            viewModel.reloadData {
                if viewModel.exercises.count == 0 {
                    refresh()
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditExercise, onDismiss: {
            viewModel.isEditHeadline = false
            viewModel.isEditExercise = false
            viewModel.reloadData {
                showAnimation.toggle()
            }
        }, content: {
            
            if viewModel.isEditHeadline {
                editNameView()
                    .presentationDetents([.height(250)])
            } else {
                editExercise()
                    .presentationDetents([.large])
            }
        })
        
        .sheet(isPresented: $viewModel.isAddNewExercise, onDismiss: {
            viewModel.isAddNewExercise = false
            viewModel.reloadData {
                showAnimation.toggle()
            }
        }, content: {
            addNewExerciseView()
        })
    }
    
    private func cells(for item: ExerciseModel) -> some View {
        
        if item.isHeadline {
            return AnyView(
                ExerciseCell(model: item) {
                    switch $0 {
                    case .update(let updateModel):
                        viewModel.edit(exercise: updateModel)
                        break
                    default:
                        break
                    }
                }
            )
        }
        
        switch editMode {
        case .active:
            return AnyView(
                ExerciseCell(model: item) {
                    switch $0 {
                    case .update(let updateModel):
                        viewModel.edit(exercise: updateModel)
                        break
                    default:
                        break
                    }
                }
            )
        default:
            return AnyView(
                NavigationLink {
                    ExerciseView(viewModel: ExerciseViewModel(exercise: item))
                } label: {
                    ExerciseCell(model: item) { _ in }
                }
            )
        }
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
            Button("New exercise", systemImage: "plus.square", action: clickBtnNewExercise)
            Button("Add headline", systemImage: "text.line.first.and.arrowtriangle.forward", action: clickBtnNewHeadline)
        } label: {
            VStack {
                Spacer()
                Image(systemName: "ellipsis")
                Spacer()
            }
        }
    }
    
    
    private func editNameView() -> some View {
        
        var title = ""
        if let value = viewModel.editExercise?.displayName {
            title = value
        }
        
        let nameItem = viewModel.isEditHeadline ? "headline" : "exercise"
        
        return EditNameView(value: title.isEmpty ? "" : title,
                            title: viewModel.editExercise == nil ? "New \(nameItem)" : "Edit \(nameItem)",
                            placeholder: "New \(nameItem) name") {
            
            switch $0 {
            case .save(let name):
                viewModel.update(name: name)
            default:
                viewModel.isEditHeadline = false
                break
            }
        }
    }
    
    @ViewBuilder
    private func editExercise() -> some View {
        if let exercise = viewModel.editExercise {
            ExerciseEditView(viewModel: ExerciseEditViewModel(exercise: exercise))
        }
    }
    
    @ViewBuilder
    private func addNewExerciseView() -> some View {
        ExerciseTypeView(mode: .selecting) { result in
            viewModel.addNewExercises(with: result)
            viewModel.isAddNewExercise = false
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
    
    private func clickBtnNewExercise() {
        viewModel.editExercise = nil
        viewModel.isAddNewExercise = true
    }
    
    private func clickBtnNewHeadline() {
        viewModel.editExercise = nil
        viewModel.isEditHeadline = true
        viewModel.isEditExercise = true
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
    ExerciseListView(viewModel: ExerciseListViewModel(group: WorkoutGroupModel(title: "TEST")))
}
