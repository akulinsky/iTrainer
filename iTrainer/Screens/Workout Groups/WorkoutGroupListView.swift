//
//  WorkoutGroupListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

enum WorkoutGroupListRoute: Hashable {
    case exerciseListView(item: WorkoutGroupModel)
}

struct WorkoutGroupListView: View {
    
    @StateObject var viewModel: WorkoutGroupListViewModel
    
    @State private var editMode = EditMode.inactive
    
    @Environment(\.navigation) private var navigation
    
    init(viewModel: WorkoutGroupListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.workoutGroups) { item in
                    cells(for: item)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .refreshable {
                refresh()
            }
            .environment(\.editMode, $editMode)
        }
        .navigationTitle(viewModel.workout.title ?? "Groups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                optionButton()
            }
        }
        .task {
            viewModel.reloadData {
                if viewModel.workoutGroups.count == 0 {
                    refresh()
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditGroup, content: {
            editNameView()
                .presentationDetents([.height(250)])
        })
        .contentSelf(content: { view in
            contentViewNavigation(content: view)
        })
    }
    
    @ViewBuilder
    private func contentViewNavigation<T: View>(content: T) -> some View {
        content
            .navigationDestination(for: WorkoutGroupListRoute.self, destination: { item in
                switch item {
                case .exerciseListView(let model):
                    ExerciseListView(viewModel: ExerciseListViewModel(group: model))
                        .environment(\.navigation, navigation)
                }
            })
    }
    
    private func cells(for item: WorkoutGroupModel) -> some View {
        WorkoutGroupCell(model: item) {
            switch $0 {
            case .update(let updateModel):
                switch editMode {
                case .active:
                    viewModel.edit(group: updateModel)
                default:
                    navigation.path.append(WorkoutGroupListRoute.exerciseListView(item: item))
                }
            default:
                break
            }
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
            Button("New group", systemImage: "plus.square", action: clickBtnNewWorkoutGroup)
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
        if let value = viewModel.editGroup?.title {
            title = value
        }
        
        return EditNameView(value: title.isEmpty ? "" : title,
                            title: viewModel.editGroup == nil ? "New group" : "Edit group",
                            placeholder: "New group name") {
            
            switch $0 {
            case .save(let name):
                viewModel.update(name: name)
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
    
    private func clickBtnNewWorkoutGroup() {
        viewModel.editGroup = nil
        viewModel.isEditGroup = true
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
    WorkoutGroupListView(viewModel: WorkoutGroupListViewModel(workout: WorkoutModel(title: "TEST")))
}
