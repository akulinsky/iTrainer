//
//  SupersetEditView.swift
//  iTrainer
//
//  Created by Codex on 15.07.2026.
//

import SwiftUI

struct SupersetEditView: View {
    @StateObject var viewModel: SupersetEditViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.navigation) private var navigation
    
    @State private var isRestTimePickerPresented = false
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if viewModel.isActiveWorkoutLocked {
                    activeWorkoutLockedView
                }
                titleView
                restTimeView
                childrenView
                deleteButton
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(AppColor.backgroundPrimary)
        .dismissKeyboardOnTap()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Edit superset")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.isPickerPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(AppColor.brandPrimary)
                .disabled(viewModel.isActiveWorkoutLocked)
            }
        }
        .keyboardAccessory(isPresented: isTitleFocused,
                           onClear: { viewModel.title = "" },
                           onDone: { isTitleFocused = false })
        .onAppear {
            viewModel.reloadData()
        }
        .onDisappear {
            if !viewModel.isDeleted {
                viewModel.save()
            }
        }
        .sheet(isPresented: $viewModel.isPickerPresented) {
            SupersetExercisePickerView(exercises: viewModel.availableExercises) { ids in
                viewModel.addSelectedExercises(ids: ids)
            }
        }
        .sheet(isPresented: $isRestTimePickerPresented) {
            DurationPickerSheet(
                title: "Superset rest",
                value: restTimeSecondsBinding,
                range: 0...600,
                secondStep: 5,
                presets: restTimePresets
            )
            .presentationDetents([.height(430)])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete superset?",
                            isPresented: $viewModel.isDeleteConfirmationPresented,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSuperset {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The superset will be removed. Its exercises will return to the workout list.")
        }
    }
    
    private var activeWorkoutLockedView: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.progressAmber)
                .frame(width: 24, height: 24)
            
            Text("Active workout in progress. Finish it before changing superset exercises.")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(AppColor.progressAmber.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColor.progressAmber.opacity(0.35), lineWidth: 1)
        }
    }
    
    private var titleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Name")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            TextField(viewModel.superset.displayName, text: $viewModel.title)
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
                .focused($isTitleFocused)
            
            Text("Leave empty to keep the generated name.")
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
    
    private var restTimeView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Rest time")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            VStack(spacing: 14) {
                HStack {
                    Text("Rest after cycle")
                        .font(AppFont.workoutGroupCardSubtitle)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Spacer()
                    
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
                    }
                    .buttonStyle(.plain)
                }
                .opacity(viewModel.switchRest ? 0.35 : 1.0)
                .allowsHitTesting(!viewModel.switchRest)
                
                Divider()
                    .overlay(AppColor.separatorSoft)
                
                Toggle("Without rest", isOn: $viewModel.switchRest)
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
    
    private var childrenView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Exercises")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Button {
                    viewModel.isPickerPresented = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColor.brandPrimary)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isActiveWorkoutLocked)
            }
            
            if viewModel.children.isEmpty {
                Text("Add at least two exercises to use this superset.")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.children.enumerated()), id: \.element.id) { index, child in
                        if index > 0 {
                            Divider()
                                .padding(.leading, 78)
                                .overlay(AppColor.separatorSoft)
                        }
                        childRow(child)
                    }
                    .onMove(perform: viewModel.moveChild)
                }
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
    
    private func childRow(_ child: ExerciseModel) -> some View {
        Button {
            navigation.path.append(ExerciseListRoute.exerciseView(item: child))
        } label: {
            ExerciseRowContent(model: child,
                               progressStatus: .none,
                               iconSize: 58,
                               minHeight: 78,
                               showsProgress: false,
                               showsIcon: true,
                               contentPadding: EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !viewModel.isActiveWorkoutLocked {
                Button {
                    viewModel.removeChild(child)
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
                .tint(AppColor.textSecondary)
                
                Button {
                    viewModel.hideChild(child)
                } label: {
                    Label("Hide", systemImage: "eye.slash")
                }
                .tint(AppColor.progressAmber)
            }
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.isDeleteConfirmationPresented = true
        } label: {
            Text("Delete Superset")
                .font(AppFont.rowTitle)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColor.separatorSoft, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isActiveWorkoutLocked)
        .opacity(viewModel.isActiveWorkoutLocked ? 0.45 : 1)
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
}
