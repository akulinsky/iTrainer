//
//  ExerciseEditView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.08.2024.
//

import SwiftUI

struct ExerciseEditView: View {
    
    @StateObject var viewModel: ExerciseEditViewModel
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var showAnimation = false
    @State private var isRestTimePickerPresented = false
    @State private var distanceUnitAccessoryRefresh = false
    
    @FocusState private var focusedInputId: String?
    
    init(viewModel: ExerciseEditViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    titleView
                    restTimeView
                    setsView
                    
                    Color.clear
                        .frame(height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(AppColor.backgroundPrimary)
            .animation(.easeInOut, value: showAnimation)
            .safeAreaPadding(.bottom, 20)
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("exercise.edit.title")
            .toolbarTitleDisplayMode(.inline)
            .keyboardAccessory(isPresented: focusedInputId != nil,
                               onClear: clearFocusedInput,
                               onDone: { focusedInputId = nil }) {
                if let focusedDistanceUnit {
                    DistanceUnitPicker(selectedUnit: focusedDistanceUnit,
                                       units: viewModel.distanceInputUnits) { unit in
                        viewModel.setFocusedDistanceUnit(unit, id: focusedInputId)
                        distanceUnitAccessoryRefresh.toggle()
                    }
                }
            }
            .toolbar {
                if presentationMode.wrappedValue.isPresented {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("common.cancel") {
                            cancel()
                        }
                        .foregroundStyle(AppColor.textSecondary)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("common.save") {
                            save()
                        }
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.brandPrimary)
                    }
                }
            }
            .onAppear {
                viewModel.reloadData()
            }
            .alert(Text("exercise.edit.save_error.title"), isPresented: $viewModel.isShowAlert) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? String(localized: "exercise.edit.save_error.message"))
            }
            .sheet(isPresented: $isRestTimePickerPresented) {
                DurationPickerSheet(
                    title: String(localized: "exercise.rest_time"),
                    value: restTimeSecondsBinding,
                    range: 0...600,
                    secondStep: 5,
                    presets: restTimePresets
                )
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func save() {
        viewModel.save { isSuccess in
            if isSuccess {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private var focusedDistanceUnit: DistanceInputUnit? {
        _ = distanceUnitAccessoryRefresh
        return viewModel.focusedDistanceUnit(id: focusedInputId)
    }
    
    private func clearFocusedInput() {
        guard let focusedInputId else {
            return
        }
        
        viewModel.clearFocusedInput(id: focusedInputId)
    }
    
    @ViewBuilder
    private var titleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("exercise.edit.custom_name")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            TextField(viewModel.exercise.type?.title ?? String(localized: "exercise.edit.name.placeholder"), text: $viewModel.title)
                .font(AppFont.rowTitle)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .foregroundStyle(AppColor.textPrimary)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColor.separatorSoft, lineWidth: 1)
                }
                .focused($focusedInputId, equals: ExerciseEditFocusId.title)
            
            Text("exercise.edit.default_name_hint")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private var restTimeView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("exercise.rest_time")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            VStack(spacing: 14) {
                HStack {
                    Text("exercise.rest_between_sets")
                        .font(AppFont.workoutGroupCardSubtitle)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Spacer()
                    
                    restTimeField
                }
                .opacity(viewModel.switchRest ? 0.35 : 1.0)
                .allowsHitTesting(!viewModel.switchRest)
                
                Divider()
                    .overlay(AppColor.separatorSoft)
                
                Toggle("superset.without_rest", isOn: $viewModel.switchRest)
                    .font(AppFont.workoutGroupCardSubtitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .tint(AppColor.brandPrimary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private var restTimeField: some View {
        Button {
            isRestTimePickerPresented = true
        } label: {
            HStack(spacing: 8) {
                Text(viewModel.restTimeDisplay)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.brandPrimary)
                    .monospacedDigit()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var restTimeSecondsBinding: Binding<Int> {
        Binding(
            get: { viewModel.restTimeSeconds },
            set: { viewModel.setRestTime(seconds: $0) }
        )
    }
    
    private var restTimePresets: [DurationPreset] {
        [
            DurationPreset(title: "0:30", seconds: 30),
            DurationPreset(title: "1:00", seconds: 60),
            DurationPreset(title: "1:30", seconds: 90),
            DurationPreset(title: "2:00", seconds: 120),
            DurationPreset(title: "3:00", seconds: 180),
            DurationPreset(title: "5:00", seconds: 300)
        ]
    }
    
    @ViewBuilder
    private var setsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("exercise.target_sets")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(Array(viewModel.setsViewModels.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 64)
                            .overlay(AppColor.separatorSoft)
                    }
                    
                    SetEditCell(viewModel: item, focusedInputId: $focusedInputId) {
                        switch $0 {
                        case .delete(let item):
                            viewModel.delete(setsViewModel: item)
                            showAnimation.toggle()
                        default:
                            break
                        }
                    }
                    .padding(.vertical, 16)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 14)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            
            Button {
                addSet()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .regular))
                    
                    Text("exercise.add_set")
                        .font(AppFont.rowTitle)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColor.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }
    
    private func addSet() {
        viewModel.add()
        showAnimation.toggle()
    }
}

#Preview {
    ExerciseEditView(viewModel: ExerciseEditViewModel(exercise: ExerciseModel(title: "Exercise GYM", typeId: "0")))
}
