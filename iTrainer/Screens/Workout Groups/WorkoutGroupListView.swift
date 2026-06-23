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
    
    @StateObject private var navigationManager = NavigationManager()
    
    init(viewModel: WorkoutGroupListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            VStack(spacing: 0) {
                if viewModel.workout == nil {
                    emptyWorkoutView()
                } else {
                    List {
                        ForEach(viewModel.workoutGroups) { item in
                            cells(for: item)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppColor.backgroundPrimary)
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppColor.backgroundPrimary)
                    .refreshable {
                        refresh()
                    }
                    .environment(\.editMode, $editMode)
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle(viewModel.workout?.title ?? "Groups")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    chooseWorkoutButton()
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
            .sheet(isPresented: $viewModel.isSelectWorkoutPresented, content: {
                WorkoutListView { workout in
                    viewModel.select(workout: workout)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            })
            .contentSelf(content: { view in
                contentViewNavigation(content: view)
            })
        }
        .environment(\.navigation, navigationManager)
    }
    
    @ViewBuilder
    private func contentViewNavigation<T: View>(content: T) -> some View {
        content
            .navigationDestination(for: WorkoutGroupListRoute.self, destination: { item in
                switch item {
                case .exerciseListView(let model):
                    ExerciseListView(viewModel: ExerciseListViewModel(group: model))
                        .environment(\.navigation, navigationManager)
                }
            })
    }
    
    private func emptyWorkoutView() -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(AppColor.textSecondary)
            Text("No workout selected")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Button("Choose workout", action: viewModel.showWorkoutPicker)
                .buttonStyle(.borderedProminent)
                .tint(AppColor.brandPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(AppColor.backgroundPrimary)
    }
    
    private func chooseWorkoutButton() -> some View {
        Button(action: viewModel.showWorkoutPicker) {
            Image(systemName: "list.bullet.rectangle")
        }
    }
    
    private func cells(for item: WorkoutGroupModel) -> some View {
        WorkoutGroupCell(model: item) {
            switch $0 {
            case .update(let updateModel):
                switch editMode {
                case .active:
                    viewModel.edit(group: updateModel)
                default:
                    navigationManager.path.append(WorkoutGroupListRoute.exerciseListView(item: item))
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
                .disabled(viewModel.workout == nil)
            Button("New group", systemImage: "plus.square", action: clickBtnNewWorkoutGroup)
                .disabled(viewModel.workout == nil)
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
        guard viewModel.workout != nil else { return }
        
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
        guard viewModel.workout != nil else { return }
        
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
