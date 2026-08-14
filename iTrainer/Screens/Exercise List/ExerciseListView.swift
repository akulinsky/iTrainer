//
//  ExerciseListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

enum ExerciseListRoute: Hashable {
    case exerciseView(item: ExerciseModel)
    case supersetEditView(item: ExerciseModel, groupId: UUID)
    case reportExerciseView(item: ReportExerciseModel)
    case reportExerciseHistoryView(item: ReportExerciseModel)
    case exerciseStatisticsView(item: ReportExerciseModel)
}

private enum ExerciseListAction: Identifiable {
    case hide(ExerciseModel)
    case delete(ExerciseModel)
    case deleteSuperset(ExerciseModel)
    
    var id: UUID {
        exercise.id
    }
    
    var exercise: ExerciseModel {
        switch self {
        case .hide(let exercise), .delete(let exercise), .deleteSuperset(let exercise):
            exercise
        }
    }
    
}

struct ExerciseListView: View {
    
    @EnvironmentObject private var workoutManager: WorkoutManager
    
    @Environment(AppState.self) private var appState
    
    @StateObject var viewModel: ExerciseListViewModel
    
    @State private var editMode = EditMode.inactive
    
    @State private var showAnimation = false
    
    @State private var isEndWorkoutAlertPresented = false
    @State private var isStartWorkoutAlertPresented = false
    @State private var pendingExerciseListAction: ExerciseListAction?
    
    @Environment(\.navigation) private var navigation
    
    init(viewModel: ExerciseListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.exercises.isEmpty {
                emptyExercisesView
            } else {
                ScrollViewReader { proxy in
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

                            if workoutManager.currentWorkoutGroupId != viewModel.group.id {
                                ActiveWorkoutContextNoticeCard()
                                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 20))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(AppColor.backgroundPrimary)
                            }
                        } else if viewModel.hasRunnableExercises {
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
                                .id(item.id)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    rowSwipeActions(for: item)
                                }
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
                .onChange(of: viewModel.pendingScrollExerciseId) { _, exerciseId in
                    guard let exerciseId else { return }
                    Task { @MainActor in
                        await Task.yield()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            proxy.scrollTo(exerciseId, anchor: .center)
                        }
                        viewModel.pendingScrollExerciseId = nil
                    }
                }
            }
            }
        }
        .background(AppColor.backgroundPrimary)
        .environment(\.defaultMinListRowHeight, 10)
        .navigationTitle(viewModel.group.title ?? String(localized: "exercise_list.title"))
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
        .onAppear {
            viewModel.reloadData()
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
                    .presentationDetents([.height(340)])
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
        .sheet(isPresented: $viewModel.isHiddenExercisesPresented) {
            HiddenExercisesView(exercises: viewModel.hiddenExercises) { exercise in
                viewModel.restore(exercise: exercise)
            }
        }
        .confirmationDialog(addConflictTitle,
                            isPresented: addConflictBinding,
                            titleVisibility: .visible,
                            actions: addConflictActions,
                            message: addConflictMessage)
        .contentSelf(content: { view in
            contentViewNavigation(content: view)
        })
        .alert(Text(workoutManager.endWorkoutAlertTitle), isPresented: $isEndWorkoutAlertPresented) {
            Button("active_workout.keep", role: .cancel) {}
            Button(workoutManager.endWorkoutActionTitle, role: .destructive) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    finishWorkout()
                }
            }
        } message: {
            Text(workoutManager.endWorkoutAlertMessage)
        }
        .alert(Text("exercise_list.start_alert.title"), isPresented: $isStartWorkoutAlertPresented) {
            Button("common.cancel", role: .cancel) {}
            Button("exercise_list.start") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    workoutManager.startWorkout(with: viewModel.group.id)
                }
            }
        } message: {
            Text(startWorkoutAlertMessage)
        }
        .alert(exerciseListActionTitle,
               isPresented: exerciseListActionBinding) {
            exerciseListActionButtons()
        } message: {
            Text(exerciseListActionMessage)
        }
    }
    
    private var exerciseListActionTitle: String {
        guard let action = pendingExerciseListAction else { return "" }
        
        switch action {
        case .hide:
            return String(localized: "exercise_list.action.hide_active.title")
        case .delete:
            return shouldWarnBeforeChangingExercises ? String(localized: "exercise_list.action.delete_active.title") : String(localized: "exercise_list.action.delete.title")
        case .deleteSuperset:
            return String(localized: "superset.delete_alert.title")
        }
    }
    
    private var exerciseListActionMessage: String {
        guard let action = pendingExerciseListAction else { return "" }
        
        switch action {
        case .hide:
            return String(localized: "exercise_list.action.active.message")
        case .delete:
            if shouldWarnBeforeChangingExercises {
                return String(localized: "exercise_list.action.delete_active.message")
            }
            return String(localized: "exercise_list.action.delete.message")
        case .deleteSuperset:
            return String(localized: "superset.delete_alert.message")
        }
    }
    
    private var startWorkoutAlertMessage: String {
        let title = viewModel.group.title ?? String(localized: "exercise_list.start_alert.default_workout")
        return String.localizedStringWithFormat(String(localized: "exercise_list.start_alert.message"), title)
    }
    
    private var exerciseListActionBinding: Binding<Bool> {
        Binding(get: {
            pendingExerciseListAction != nil
        }, set: { isPresented in
            if !isPresented {
                pendingExerciseListAction = nil
            }
        })
    }
    
    @ViewBuilder
    private func exerciseListActionButtons() -> some View {
        if let action = pendingExerciseListAction {
            Button("common.cancel", role: .cancel) {
                pendingExerciseListAction = nil
            }
            switch action {
            case .hide:
                Button("common.hide") {
                    performExerciseListAction(action)
                }
            case .delete, .deleteSuperset:
                Button("common.delete", role: .destructive) {
                    performExerciseListAction(action)
                }
            }
        }
    }
    
    private func performExerciseListAction(_ action: ExerciseListAction) {
        pendingExerciseListAction = nil
        switch action {
        case .hide(let exercise):
            viewModel.hide(exercise: exercise)
        case .delete(let exercise), .deleteSuperset(let exercise):
            viewModel.delete(exercise: exercise)
        }
    }
    
    @ViewBuilder
    private func contentViewNavigation<T: View>(content: T) -> some View {
        content
            .navigationDestination(for: ExerciseListRoute.self, destination: { item in
                switch item {
                case .exerciseView(let model):
                    ExerciseView(viewModel: ExerciseViewModel(exercise: model))
                        .id(model.id)
                        .environment(\.navigation, navigation)
                case .supersetEditView(let model, let groupId):
                    SupersetEditView(viewModel: SupersetEditViewModel(superset: model,
                                                                       groupId: groupId,
                                                                       isActiveWorkoutLocked: workoutManager.isWorkoutInProgress && workoutManager.currentWorkoutGroupId == groupId),
                                     onClose: {
                                        viewModel.reloadData()
                                     })
                        .environment(\.navigation, navigation)
                case .reportExerciseView(let model):
                    ReportExerciseView(viewModel: ReportExerciseViewModel(reportExercise: model),
                                       onOpenStatistics: { exercise in
                                        navigation.path.append(ExerciseListRoute.exerciseStatisticsView(item: exercise))
                                       },
                                       onOpenHistory: { exercise in
                                        navigation.path.append(ExerciseListRoute.reportExerciseHistoryView(item: exercise))
                                       })
                case .reportExerciseHistoryView(let model):
                    ReportExerciseHistoryView(viewModel: ReportExerciseHistoryViewModel(reportExercise: model))
                case .exerciseStatisticsView(let model):
                    ExerciseStatisticsView(exercise: model)
                }
            })
    }
    
    private var addConflictTitle: String {
        viewModel.addConflict?.title ?? ""
    }
    
    private var addConflictBinding: Binding<Bool> {
        Binding(get: {
            viewModel.addConflict != nil
        }, set: { isPresented in
            if !isPresented {
                viewModel.addConflict = nil
            }
        })
    }
    
    @ViewBuilder
    private func addConflictActions() -> some View {
        if let conflict = viewModel.addConflict {
            switch conflict {
            case .activeDuplicate:
                Button("exercise_list.add_conflict.add_anyway") {
                    viewModel.addPendingExercisesAnyway()
                }
            case .hiddenDuplicate:
                Button("common.restore") {
                    viewModel.restorePendingHiddenExercises()
                }
                Button("exercise_list.add_conflict.add_new_copy") {
                    viewModel.addPendingExercisesAnyway()
                }
            }
            Button("common.cancel", role: .cancel) {
                viewModel.addConflict = nil
            }
        }
    }
    
    @ViewBuilder
    private func addConflictMessage() -> some View {
        if let conflict = viewModel.addConflict {
            Text(conflict.message)
        }
    }
    
    private func cells(for item: ExerciseModel) -> some View {
        Group {
            if item.isSupersetItem {
                SupersetCell(model: item,
                             editMode: editMode,
                             progressStatus: progressStatus(for:),
                             action: handleSupersetAction)
            } else {
                ExerciseCell(model: item,
                             progressStatus: progressStatus(for: item)) {
                    switch $0 {
                    case .update(let updateModel):
                        switch editMode {
                        case .active:
                            viewModel.edit(exercise: updateModel)
                        default:
                            if !item.isHeadlineItem {
                                navigation.path.append(ExerciseListRoute.exerciseView(item: item))
                            }
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func handleSupersetAction(_ action: SupersetCell.Action) {
        switch action {
        case .edit(let superset):
            navigation.path.append(ExerciseListRoute.supersetEditView(item: superset, groupId: viewModel.group.id))
        case .openChild(let child):
            switch editMode {
            case .active:
                viewModel.edit(exercise: child)
            default:
                navigation.path.append(ExerciseListRoute.exerciseView(item: child))
            }
        }
    }
    
    private var emptyExercisesView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 44))
                .foregroundStyle(AppColor.textSecondary)
            Text("exercise_list.empty.title")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("exercise_list.empty.subtitle")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("exercise_list.empty.add", action: clickBtnNewExercise)
                .buttonStyle(.borderedProminent)
                .tint(AppColor.brandPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(AppColor.backgroundPrimary)
    }
    
    private var workoutStatusWidget: some View {
        WorkoutStatusWidget(title: workoutManager.currentWorkoutTitle,
                            workoutTime: workoutManager.workoutElapsedTime,
                            restTime: workoutManager.currentRestTime,
                            restProgress: workoutManager.progressRestTime,
                            workoutProgress: workoutManager.workoutProgress,
                            onEndTap: {
                                isEndWorkoutAlertPresented = true
                            },
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
        WorkoutStartCard(workoutTitle: viewModel.group.title ?? String(localized: "exercise_list.workout_session")) {
            isStartWorkoutAlertPresented = true
        }
    }
    
    private func progressStatus(for item: ExerciseModel) -> ExerciseProgressStatus {
        guard !item.isHeadlineItem, !item.isSupersetItem else {
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
        if item.isHeadlineItem, editMode != .active {
            return EdgeInsets(top: 16, leading: 20, bottom: 4, trailing: 20)
        }
        return EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)
    }
    
    @ViewBuilder
    private func rowSwipeActions(for item: ExerciseModel) -> some View {
        if item.isSupersetItem {
            Button {
                requestExerciseListAction(.deleteSuperset(item))
            } label: {
                Label("common.delete", systemImage: "trash")
            }
            .tint(.red)
        } else if !item.isHeadlineItem {
            Button {
                requestExerciseListAction(.delete(item))
            } label: {
                Label("common.delete", systemImage: "trash")
            }
            .tint(.red)
            
            Button {
                requestExerciseListAction(.hide(item))
            } label: {
                Label("common.hide", systemImage: "eye.slash")
            }
            .tint(AppColor.progressAmber)
        }
    }
    
    private func requestExerciseListAction(_ action: ExerciseListAction) {
        switch action {
        case .delete, .deleteSuperset:
            pendingExerciseListAction = action
        case .hide:
            if shouldWarnBeforeChangingExercises {
                pendingExerciseListAction = action
            } else {
                performExerciseListAction(action)
            }
        }
    }
    
    private var shouldWarnBeforeChangingExercises: Bool {
        workoutManager.isWorkoutInProgress && workoutManager.currentWorkoutGroupId == viewModel.group.id
    }
    
    private func optionButton() -> some View {
        switch editMode {
        case .active:
            return AnyView(Button("common.done", action: clickBtnDone).bold())
        default:
            return AnyView(menuItem())
        }
    }
    
    private func menuItem() -> some View {
        Menu {
            Button("common.edit", systemImage: "pencil", action: clickBtnEditint)
            Button("exercise_list.new_exercise", systemImage: "plus.square", action: clickBtnNewExercise)
            Button("superset.add", systemImage: "link", action: clickBtnNewSuperset)
            Button("exercise_list.add_headline", systemImage: "text.line.first.and.arrowtriangle.forward", action: clickBtnNewHeadline)
            if viewModel.hasHiddenExercises {
                Button("exercise_list.hidden.title", systemImage: "eye.slash", action: clickBtnHiddenExercises)
            }
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
        
        if viewModel.isEditHeadline {
            return AnyView(EditTaggedNameView(value: title.isEmpty ? "" : title,
                                              title: viewModel.editExercise == nil ? String(localized: "exercise_list.headline.new") : String(localized: "exercise_list.headline.edit"),
                                              placeholder: String(localized: "exercise_list.headline.name.placeholder"),
                                              tags: categoryTags) {
                switch $0 {
                case .save(let name):
                    viewModel.update(name: name)
                default:
                    viewModel.isEditHeadline = false
                    break
                }
            })
        }
        
        return AnyView(EditNameView(value: title.isEmpty ? "" : title,
                                    title: viewModel.editExercise == nil ? String(localized: "exercise_list.exercise.new") : String(localized: "exercise_list.exercise.edit"),
                                    placeholder: String(localized: "exercise_list.exercise.name.placeholder")) {
            switch $0 {
            case .save(let name):
                viewModel.update(name: name)
            default:
                viewModel.isEditHeadline = false
                break
            }
        })
    }
    
    private var categoryTags: [String] {
        DataContainer.shared.categories.map(\.displayName)
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
        viewModel.isEditHeadline = false
        viewModel.isAddNewExercise = true
    }
    
    private func clickBtnNewHeadline() {
        viewModel.editExercise = nil
        viewModel.isEditHeadline = true
        viewModel.isEditExercise = true
    }
    
    private func clickBtnNewSuperset() {
        viewModel.addSuperset { superset in
            if let superset {
                navigation.path.append(ExerciseListRoute.supersetEditView(item: superset, groupId: viewModel.group.id))
            }
        }
    }
    
    private func clickBtnHiddenExercises() {
        viewModel.isHiddenExercisesPresented = true
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
        
        if let exercise = viewModel.exercises.flattenedExerciseItems().first(where: { $0.id == activeExerciseId }) {
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
        for index in offsets {
            viewModel.delete(index: index)
        }
    }
    
    private func moveItems(source: IndexSet, destination: Int) {
        viewModel.moveItem(source: source, destination: destination)
    }
}

#Preview {
    ExerciseListView(viewModel: ExerciseListViewModel(group: WorkoutGroupModel(title: "TEST")))
}
