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
    
    @EnvironmentObject private var workoutManager: WorkoutManager
    
    @StateObject var viewModel: WorkoutGroupListViewModel
    
    @State private var editMode = EditMode.inactive
    
    @State private var isEndWorkoutAlertPresented = false
    
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
                        if workoutManager.isWorkoutInProgress {
                            workoutStatusWidget
                                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 12, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppColor.backgroundPrimary)
                        }
                        
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
            .navigationBarTitleDisplayMode(.inline)
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
            .alert("Finish workout?", isPresented: $isEndWorkoutAlertPresented) {
                Button("Cancel", role: .cancel) {}
                Button("Finish", role: .destructive) {
                    workoutManager.endWorkout()
                }
            } message: {
                Text("Current workout will be closed.")
            }
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
    
    private var workoutStatusWidget: some View {
        WorkoutStatusWidget(title: workoutManager.currentWorkoutTitle,
                            workoutTime: workoutManager.workoutElapsedTime,
                            restTime: workoutManager.currentRestTime,
                            restProgress: workoutManager.progressRestTime,
                            workoutProgress: workoutManager.workoutProgress,
                            onWorkoutTap: {
                                isEndWorkoutAlertPresented = true
                            },
                            onRestTap: {
                                navigateToActiveExercise()
                            },
                            onProgressTap: {
                                navigateToActiveExercise()
                            })
    }
    
    private func cells(for item: WorkoutGroupModel) -> some View {
        return WorkoutGroupCell(model: item,
                                progress: progress(for: item),
                                status: status(for: item),
                                exerciseCount: viewModel.exerciseCount(for: item.id)) {
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
    
    private func progress(for item: WorkoutGroupModel) -> Double {
        if workoutManager.currentWorkoutGroupId == item.id {
            return workoutManager.workoutProgress
        }
        
        return viewModel.lastCompletedProgress(for: item.id)
    }
    
    private func status(for item: WorkoutGroupModel) -> WorkoutGroupStatus {
        if workoutManager.currentWorkoutGroupId == item.id {
            return .active
        }
        
        if viewModel.isLastCompletedGroup(item.id) {
            return .lastCompleted
        }
        
        return .normal
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
    
    private func navigateToActiveExercise() {
        guard let currentGroupId = workoutManager.currentWorkoutGroupId,
              let activeExerciseId = workoutManager.activeExerciseId else {
            return
        }
        
        let group = viewModel.workoutGroups.first(where: { $0.id == currentGroupId })
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let activeGroup: WorkoutGroupModel?
            if let group {
                activeGroup = group
            } else {
                activeGroup = await dataManager.fetchWorkoutGroup(with: currentGroupId).map { WorkoutGroupModel(model: $0) }
            }
            let activeExercise = await dataManager.fetchExercise(with: activeExerciseId).map { ExerciseModel(model: $0) }
            
            await MainActor.run {
                guard let activeGroup, let activeExercise else {
                    return
                }
                
                navigationManager.path.append(WorkoutGroupListRoute.exerciseListView(item: activeGroup))
                DispatchQueue.main.async {
                    navigationManager.path.append(ExerciseListRoute.exerciseView(item: activeExercise))
                }
            }
        }
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
