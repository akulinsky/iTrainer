//
//  ExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI
import Combine

struct ExerciseView: View {
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @Environment(\.navigation) private var navigation
    
    @StateObject var viewModel: ExerciseViewModel
    
    @State private var showAnimation = false
    
    @State private var isEndWorkoutAlertPresented = false
    
    @State private var isExerciseInfoPresented = false
    
    @FocusState private var focusedParamId: Int?
    
    init(viewModel: ExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
        .dismissKeyboardOnTap()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit", systemImage: "pencil", action: clickBtnEditint)
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
        .alert("Finish workout?", isPresented: $isEndWorkoutAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Finish", role: .destructive) {
                workoutManager.endWorkout()
            }
        } message: {
            Text("Current workout will be closed.")
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
        Button {
            isExerciseInfoPresented = true
        } label: {
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
                        Text("Rest \(viewModel.exercise.restTime.minuteSecond)")
                            .font(AppFont.rowSubtitle)
                            .foregroundStyle(AppColor.textSecondary)
                        
                        Spacer(minLength: 12)
                        
                        Image(systemName: "info.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColor.textSecondary)
                            .padding(.trailing, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(minHeight: 112)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.title), \(exerciseMetadata)")
            .accessibilityHint("Open exercise information")
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $isExerciseInfoPresented) {
            if let type = viewModel.exercise.type {
                ExerciseCatalogDetailView(model: type)
            }
        }
    }
    
    @ViewBuilder
    private var exerciseIcon: some View {
        if let icon = viewModel.exercise.type?.icon {
            icon
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Image("icMissingImage")
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private var exerciseMetadata: String {
        guard let type = viewModel.exercise.type else {
            return ""
        }
        return "\(type.type.displayName) · \(type.displayName)"
    }
    
    private var targetSetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Target sets")
            
            VStack(spacing: 8) {
                ForEach(viewModel.sets) { item in
                    SetsCell(model: item) {
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
    
    private var addResultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Add result")
            
            HStack(spacing: 10) {
                ForEach($viewModel.paramsData) { $item in
                    addResultTextField(item: item, value: $item.value)
                }
                
                Button(action: prepareToSave) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle")
                        Text("Add")
                    }
                    .font(AppFont.rowTitle)
                    .foregroundStyle(.white)
                    .frame(width: 92)
                    .frame(height: 48)
                    .background(AppColor.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
    }
    
    private func addResultTextField(item: ExerciseViewModel.ParamData, value: Binding<String>) -> some View {
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
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
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
            sectionTitle(reportExercise.date?.formatted(date: .long, time: .omitted) ?? "History")
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
    
    @ViewBuilder
    private func editSets() -> some View {
        EditSetsView(title: viewModel.editSets == nil ? "New sets" : "Edit sets",
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
        EditSetsView(title: "Edit report sets",
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
                navigation.path.append(ExerciseListRoute.exerciseView(item: exercise))
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
}
