//
//  ExerciseListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

enum ExerciseListRoute: Hashable {
    case exerciseView(item: ExerciseModel)
}

struct ExerciseListView: View {
    
    @StateObject var viewModel: ExerciseListViewModel
    
    @State private var editMode = EditMode.inactive
    
    @State private var showAnimation = false
    
    @Environment(\.navigation) private var navigation
    
    init(viewModel: ExerciseListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                workoutStatusWidget
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 12, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppColor.backgroundPrimary)
                
                ForEach(viewModel.exercises) { item in
                    cells(for: item)
                        .listRowInsets(rowInsets(for: item))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.backgroundPrimary)
            .animation(.easeInOut, value: showAnimation)
            .refreshable {
                refresh()
            }
            .environment(\.editMode, $editMode)
        }
        .background(AppColor.backgroundPrimary)
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
        .contentSelf(content: { view in
            contentViewNavigation(content: view)
        })
    }
    
    @ViewBuilder
    private func contentViewNavigation<T: View>(content: T) -> some View {
        content
            .navigationDestination(for: ExerciseListRoute.self, destination: { item in
                switch item {
                case .exerciseView(let model):
                    ExerciseView(viewModel: ExerciseViewModel(exercise: model))
                        .environment(\.navigation, navigation)
                }
            })
    }
    
    private func cells(for item: ExerciseModel) -> some View {
        let index = viewModel.exercises.filter { !$0.isHeadline }.firstIndex { $0.id == item.id } ?? 0
        
        return ExerciseCell(model: item,
                            progressStatus: progressStatus(for: index, item: item)) {
            switch $0 {
            case .update(let updateModel):
                switch editMode {
                case .active:
                    viewModel.edit(exercise: updateModel)
                default:
                    if !item.isHeadline {
                        navigation.path.append(ExerciseListRoute.exerciseView(item: item))
                    }
                }
            default:
                break
            }
        }
    }
    
    private var workoutStatusWidget: some View {
        WorkoutStatusWidget(workoutTime: 9805,
                            restTime: 38,
                            restProgress: 0.72,
                            workoutProgress: 0.64)
    }
    
    private func progressStatus(for index: Int, item: ExerciseModel) -> ExerciseProgressStatus {
        guard !item.isHeadline else {
            return .none
        }
        
        switch index {
        case 0:
            return .active(progress: 0.64)
        case 1:
            return .completed(progress: 1)
        default:
            return .none
        }
    }
    
    private func rowInsets(for item: ExerciseModel) -> EdgeInsets {
        if item.isHeadline, editMode != .active {
            return EdgeInsets(top: 16, leading: 20, bottom: 4, trailing: 20)
        }
        return EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)
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
