//
//  ExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI
import Combine

struct ExerciseView: View {
    
    @State private var currentExercise: ExerciseModel
    
    @State private var currentExerciseRefreshId = UUID()
    
    init(viewModel: ExerciseViewModel) {
        _currentExercise = State(initialValue: viewModel.exercise)
    }
    
    var body: some View {
        ZStack {
            ExerciseContentView(viewModel: ExerciseViewModel(exercise: currentExercise)) { nextExercise in
                withAnimation(.easeInOut(duration: 0.28)) {
                    currentExercise = nextExercise
                    currentExerciseRefreshId = UUID()
                }
            }
            .id(currentExerciseRefreshId)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }
}

private struct ExerciseContentView: View {
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @EnvironmentObject private var appSettings: AppSettings
    
    @Environment(AppState.self) private var appState
    
    @Environment(\.navigation) private var navigation
    
    @StateObject var viewModel: ExerciseViewModel
    
    @State private var showAnimation = false
    
    @State private var isEndWorkoutAlertPresented = false
    
    @State private var isExerciseInfoPresented = false
    
    @FocusState private var focusedParamId: Int?
    
    private let onNextExercise: (ExerciseModel) -> Void
    
    private var distanceInputUnits: [DistanceInputUnit] {
        DistanceInputUnit.units(for: appSettings.resolvedDistanceUnit)
    }
    
    private var focusedDistanceParam: ExerciseViewModel.ParamData? {
        guard let focusedParamId else {
            return nil
        }
        return viewModel.paramsData.first { $0.id == focusedParamId && $0.isDistance }
    }
    
    init(viewModel: ExerciseViewModel, onNextExercise: @escaping (ExerciseModel) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNextExercise = onNextExercise
    }
    
    var body: some View {
        List {
            if workoutManager.isWorkoutInProgress {
                workoutStatusWidget
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 12, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppColor.backgroundPrimary)
            }
            
            exerciseHeaderCard
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(AppColor.backgroundPrimary)
            
            targetSetsSection
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(AppColor.backgroundPrimary)
            
            addResultSection
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(AppColor.backgroundPrimary)
            
            completedSetsSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .animation(.easeInOut(duration: 0.24), value: workoutManager.isWorkoutInProgress)
        .animation(.easeInOut, value: showAnimation)
        .safeAreaPadding(.bottom, 20)
        .scrollDismissesKeyboard(.immediately)
        .keyboardAccessory(isPresented: focusedParamId != nil,
                           onClear: clearFocusedInput,
                           onDone: { focusedParamId = nil }) {
            if let focusedDistanceParam {
                DistanceUnitPicker(selectedUnit: focusedDistanceParam.distanceUnit,
                                   units: distanceInputUnits,
                                   onSelect: setFocusedDistanceUnit)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("common.edit", systemImage: "pencil", action: clickBtnEditint)
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
                .presentationDetents([.height(250)])
        })
        .sheet(isPresented: $viewModel.isEditReportSets, content: {
            editReportSets()
                .presentationDetents([.height(250)])
        })
        .sheet(isPresented: $viewModel.isEditExercise, onDismiss: {
            viewModel.reloadData {
                showAnimation.toggle()
            }
        }, content: {
            editExercise()
                .presentationDetents([.large])
        })
        .alert(Text("active_workout.finish_alert.title"), isPresented: $isEndWorkoutAlertPresented) {
            Button("common.cancel", role: .cancel) {}
            Button("active_workout.finish", role: .destructive) {
                finishWorkout()
            }
        } message: {
            Text(workoutManager.finishWorkoutAlertMessage)
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
    
    private var exerciseHeaderCard: some View {
        VStack(spacing: 0) {
            Button {
                isExerciseInfoPresented = true
            } label: {
                exerciseHeaderContent
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.title), \(exerciseMetadata)")
            .accessibilityHint(Text("exercise.info.accessibility_hint"))
            
            if let latestReportExercise = viewModel.reportExercises.first {
                Divider()
                    .padding(.horizontal, 12)
                latestReportButton(latestReportExercise)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
        .navigationDestination(isPresented: $isExerciseInfoPresented) {
            if let type = viewModel.exercise.type {
                ExerciseCatalogDetailView(model: type)
            }
        }
    }
    
    private var exerciseHeaderContent: some View {
        HStack(spacing: 14) {
            exerciseIcon
            
            VStack(alignment: .leading, spacing: 7) {
                Text(viewModel.title)
                    .font(AppFont.workoutGroupCardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                
                Text(exerciseMetadata)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                
                HStack(alignment: .center) {
                    Text(restTimeText)
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                    
                    Spacer(minLength: 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(minHeight: 112)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.brandPrimary)
                .frame(width: 38, height: 38)
                .padding(.top, -6)
                .padding(.trailing, -6)
        }
        .contentShape(Rectangle())
    }
    
    private func latestReportButton(_ reportExercise: ReportExerciseModel) -> some View {
        Button {
            navigation.path.append(ExerciseListRoute.reportExerciseView(item: reportExercise))
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 22)
                Text("exercise.latest_report")
                    .font(AppFont.rowTitle)
                Spacer(minLength: 12)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(AppColor.brandPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("exercise.latest_report"))
    }
    
    private var exerciseIcon: some View {
        ExerciseTypeIconView(exerciseType: viewModel.exercise.type,
                             size: 88,
                             cornerRadius: 12,
                             symbolSize: 36)
    }
    
    private var exerciseMetadata: String {
        guard let type = viewModel.exercise.type else {
            return ""
        }
        
        let groupTitle = isSupersetChild ? String(localized: "superset.title") : type.type.displayName
        let typeTitle = type.displayName
        
        if viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(typeTitle.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame {
            return groupTitle
        }
        
        return "\(groupTitle) · \(typeTitle)"
    }
    
    private var restTimeText: String {
        guard viewModel.exercise.restTime > 0 else {
            return String(localized: "superset.without_rest")
        }
        return String.localizedStringWithFormat(String(localized: "exercise.rest_time.value"), viewModel.exercise.restTime.minuteSecond)
    }
    
    private var isSupersetChild: Bool {
        viewModel.exercise.parentSupersetId != nil
    }
    
    private var targetSetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(String(localized: "exercise.target_sets"))
            
            if viewModel.sets.isEmpty {
                noTargetSetsView
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.sets.enumerated()), id: \.element.id) { index, item in
                        SetsCell(model: item,
                                 targetStatus: targetSetStatus(at: index)) {
                            switch $0 {
                            case .update(let updateModel):
                                viewModel.edit(sets: updateModel)
                            case .selected(let selectedModel):
                                viewModel.addResult(with: selectedModel.parameters)
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var noTargetSetsView: some View {
        Button(action: clickBtnEditint) {
            VStack(alignment: .leading, spacing: 4) {
                Text("exercise.no_target_sets")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                
                Text("exercise.no_target_sets.subtitle")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func targetSetStatus(at index: Int) -> SetsCell.TargetStatus {
        guard workoutManager.isWorkoutInProgress,
              viewModel.isActiveWorkoutExercise else {
            return .inactive
        }
        
        return index < viewModel.activeReportSetCount ? .completed : .pending
    }
    
    private var shouldShowCompletedGoalActions: Bool {
        workoutManager.isWorkoutInProgress && viewModel.shouldShowCompletedGoalActions
    }
    
    private var addResultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(isSupersetChild ? String(localized: "exercise.add_superset_result") : String(localized: "exercise.add_result"))
            
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach($viewModel.paramsData) { $item in
                        addResultTextField(item: item, value: $item.value)
                    }
                    
                    compactAddResultButton
                }
                
                if shouldShowCompletedGoalActions {
                    completedGoalActionButtons
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: shouldShowCompletedGoalActions)
            .padding(12)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
    }
    
    private var compactAddResultButton: some View {
        Button(action: prepareToSave) {
            Image(systemName: "plus")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 58)
            .frame(height: 48)
            .background(AppColor.brandPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("common.add"))
    }
    
    private var completedGoalActionButtons: some View {
        resultActionButton(title: viewModel.nextExercise == nil ? String(localized: "exercise.finish_workout") : String(localized: "exercise.next_exercise"),
                           systemImage: viewModel.nextExercise == nil ? "flag.checkered" : "arrow.right.circle",
                           foreground: .white,
                           background: viewModel.nextExercise == nil ? AppColor.workoutGreen : AppColor.brandPrimary,
                           border: .clear,
                           action: performCompletedGoalAction)
    }
    
    private func resultActionButton(title: String,
                                    systemImage: String,
                                    foreground: Color,
                                    background: Color,
                                    border: Color,
                                    action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .font(AppFont.rowTitle)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func addResultTextField(item: ExerciseViewModel.ParamData, value: Binding<String>) -> some View {
        VStack(spacing: 4) {
            TextField(item.param.title, text: value, onEditingChanged: { focused in
                self.viewModel.focused(focused, paramData: item)
            })
            .font(AppFont.rowTitle)
            .foregroundStyle(AppColor.textPrimary)
            .keyboardType(item.keyboardType)
            .focused($focusedParamId, equals: item.id)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .shakeAnimation(item.shake)
            .onChange(of: value.wrappedValue) { _, newValue in
                sanitizeDistanceInput(item: item, value: value, newValue: newValue)
            }
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            
            Text(item.unitText)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedParamId = item.id
        }
    }
    
    @ViewBuilder
    private var completedSetsSection: some View {
        if !viewModel.reportExercises.isEmpty {
            ForEach(viewModel.reportExercises) { exercise in
                Section {
                    ForEach(exercise.sets) { item in
                        ReportSetsCell(reportSet: item) {
                            switch $0 {
                            case .update(let updateModel):
                                viewModel.editReport(sets: updateModel)
                            case .selected(let selectedModel):
                                viewModel.addResult(with: selectedModel.parameters)
                            default:
                                break
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                    }
                    .onDelete(perform: { deleteReport(offsets: $0, reportExerciseId: exercise.id) })
                } header: {
                    reportSetsHeaderView(reportExercise: exercise)
                }
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppFont.caption)
            .foregroundStyle(AppColor.textSecondary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
    }
    
    private func reportSetsHeaderView(reportExercise: ReportExerciseModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle(reportExercise.date?.formatted(date: .long, time: .omitted) ?? String(localized: "reports.history.title"))
                .padding(.leading, 20)
                .padding(.top, 12)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.backgroundPrimary)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    private func prepareToSave() {
        focusedParamId = nil
        viewModel.save {
            viewModel.clearParamsDataValues()
            showAnimation.toggle()
        }
    }
    
    private func clearFocusedInput() {
        guard let focusedParamId,
              let paramData = viewModel.paramsData.first(where: { $0.id == focusedParamId }) else {
            return
        }
        
        paramData.value = ""
    }
    
    private func sanitizeDistanceInput(item: ExerciseViewModel.ParamData,
                                       value: Binding<String>,
                                       newValue: String) {
        guard item.isDistance else {
            return
        }
        
        let sanitizedValue = item.distanceUnit.sanitizedInputText(newValue)
        if sanitizedValue != newValue {
            value.wrappedValue = sanitizedValue
        }
    }
    
    private func setFocusedDistanceUnit(_ unit: DistanceInputUnit) {
        guard let paramData = focusedDistanceParam,
              paramData.distanceUnit != unit else {
            return
        }
        
        paramData.value = unit.convertedText(from: paramData.value, previousUnit: paramData.distanceUnit)
        paramData.distanceUnit = unit
    }
    
    @ViewBuilder
    private func editSets() -> some View {
        EditSetsView(title: viewModel.editSets == nil ? String(localized: "exercise.sets.new") : String(localized: "exercise.sets.edit"),
                     params: viewModel.editSets?.parameters ?? []) {
            switch $0 {
            case .save(let params):
                viewModel.update(params: params)
            default:
                break
            }
        }
    }
    
    @ViewBuilder
    private func editReportSets() -> some View {
        EditSetsView(title: String(localized: "exercise.report_sets.edit"),
                     params: viewModel.editReportSets?.parameters ?? []) {
            switch $0 {
            case .save(let params):
                viewModel.updateReport(params: params)
            default:
                break
            }
        }
    }
    
    @ViewBuilder
    private func editExercise() -> some View {
        ExerciseEditView(viewModel: ExerciseEditViewModel(exercise: viewModel.exercise))
    }
    
    private func clickBtnEditint() {
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
    
    private func performCompletedGoalAction() {
        if viewModel.nextExercise == nil {
            isEndWorkoutAlertPresented = true
        } else {
            goToNextExercise()
        }
    }
    
    private func goToNextExercise() {
        guard let nextExercise = viewModel.nextExercise else {
            return
        }
        
        onNextExercise(nextExercise)
    }
    
    private func navigateToActiveExercise() {
        guard let activeExerciseId = workoutManager.activeExerciseId else {
            return
        }
        
        if activeExerciseId == viewModel.exercise.id {
            return
        }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            guard let exercise = await dataManager.fetchExercise(with: activeExerciseId).map({ ExerciseModel(model: $0) }) else {
                return
            }
            
            await MainActor.run {
                onNextExercise(exercise)
            }
        }
    }
    
    private func deleteReport(offsets: IndexSet, reportExerciseId: UUID) {
        withAnimation {
            viewModel.deleteReportSets(offsets: offsets, reportExerciseId: reportExerciseId)
        }
    }
}

#Preview {
    ExerciseView(viewModel: ExerciseViewModel(exercise: ExerciseModel(title: "Bench Press", typeId: "0")))
        .environmentObject(AppSettings())
}
