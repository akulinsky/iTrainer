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
    
    @EnvironmentObject private var workoutManager: WorkoutManager
    
    @Environment(AppState.self) private var appState
    
    @StateObject var viewModel: ExerciseListViewModel
    
    @State private var editMode = EditMode.inactive
    
    @State private var showAnimation = false
    
    @State private var isEndWorkoutAlertPresented = false
    @State private var isStartWorkoutAlertPresented = false
    
    @Environment(\.navigation) private var navigation
    
    init(viewModel: ExerciseListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                if workoutManager.isWorkoutInProgress {
                    workoutStatusWidget
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.96).combined(with: .opacity)
                        ))
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 12, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                } else {
                    startSessionCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.96).combined(with: .opacity)
                        ))
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 12, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                }
                
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
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: workoutManager.isWorkoutInProgress)
            .refreshable {
                refresh()
            }
            .environment(\.editMode, $editMode)
        }
        .background(AppColor.backgroundPrimary)
        .environment(\.defaultMinListRowHeight, 10)
        .navigationTitle(viewModel.group.title ?? "Exercises")
        .navigationBarTitleDisplayMode(.inline)
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
        .alert("Finish workout?", isPresented: $isEndWorkoutAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Finish", role: .destructive) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    finishWorkout()
                }
            }
        } message: {
            Text(workoutManager.finishWorkoutAlertMessage)
        }
        .alert("Start workout?", isPresented: $isStartWorkoutAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Start") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    workoutManager.startWorkout(with: viewModel.group.id)
                }
            }
        } message: {
            Text("Start \(viewModel.group.title ?? "this workout")?")
        }
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
        return ExerciseCell(model: item,
                            progressStatus: progressStatus(for: item)) {
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
    
    private var startSessionCard: some View {
        Button {
            isStartWorkoutAlertPresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.workoutGreen)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start workout")
                        .font(AppFont.workoutGroupCardTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Text(viewModel.group.title ?? "Workout session")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func progressStatus(for item: ExerciseModel) -> ExerciseProgressStatus {
        guard !item.isHeadline else {
            return .none
        }
        
        let isCurrentWorkoutGroup = workoutManager.currentWorkoutGroupId == viewModel.group.id
        
        if workoutManager.activeExerciseId == item.id,
           isCurrentWorkoutGroup,
           let progress = workoutManager.exerciseProgressById[item.id] {
            return .active(progress: progress)
        }
        
        if isCurrentWorkoutGroup {
            guard let progress = workoutManager.exerciseProgressById[item.id] else {
                return .none
            }
            return .completed(progress: progress)
        }
        
        if let progress = viewModel.lastCompletedProgress(for: item.id) {
            return .completed(progress: progress)
        }
        
        return .none
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
    
    private func finishWorkout() {
        workoutManager.endWorkout { report in
            appState.reportToPresent = report
        }
    }
    
    private func navigateToActiveExercise() {
        guard let activeExerciseId = workoutManager.activeExerciseId else {
            return
        }
        
        if let exercise = viewModel.exercises.first(where: { $0.id == activeExerciseId }) {
            navigation.path.append(ExerciseListRoute.exerciseView(item: exercise))
            return
        }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            guard let exercise = await dataManager.fetchExercise(with: activeExerciseId).map({ ExerciseModel(model: $0) }) else {
                return
            }
            
            await MainActor.run {
                navigation.path.append(ExerciseListRoute.exerciseView(item: exercise))
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
    ExerciseListView(viewModel: ExerciseListViewModel(group: WorkoutGroupModel(title: "TEST")))
}
