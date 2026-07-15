//
//  SupersetEditView.swift
//  iTrainer
//
//  Created by Codex on 15.07.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct SupersetEditView: View {
    @StateObject var viewModel: SupersetEditViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.navigation) private var navigation
    
    @State private var isRestTimePickerPresented = false
    @State private var draggingChild: ExerciseModel?
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        List {
            if viewModel.isActiveWorkoutLocked {
                activeWorkoutLockedView
                    .listRowStyle(top: 20, bottom: 6)
            }
            
            titleView
                .listRowStyle(top: viewModel.isActiveWorkoutLocked ? 6 : 20, bottom: 10)
            
            restTimeView
                .listRowStyle(top: 10, bottom: 10)
            
            childrenHeaderRow
                .listRowStyle(top: 12, bottom: 4)
            
            if viewModel.children.isEmpty {
                emptyChildrenPrompt
                    .listRowStyle(top: 4, bottom: 10)
            } else {
                ForEach(viewModel.children) { child in
                    childRow(child)
                        .listRowStyle(top: 6, bottom: 6)
                        .onDrop(of: [.text],
                                delegate: SupersetChildDropDelegate(
                                    target: child,
                                    draggingChild: $draggingChild,
                                    moveAction: { draggedId, targetId in
                                        viewModel.moveChild(draggedId: draggedId, to: targetId)
                                    }
                                ))
                }
                .onMove(perform: viewModel.moveChild)
                
                if viewModel.children.count == 1 {
                    oneChildPrompt
                        .listRowStyle(top: 2, bottom: 10)
                }
            }
            
            deleteButton
                .listRowStyle(top: 18, bottom: 24)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: viewModel.children.map(\.id))
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
        .alert("Delete superset?", isPresented: $viewModel.isDeleteConfirmationPresented) {
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
    
    private var childrenHeaderRow: some View {
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
        .padding(.horizontal, 2)
    }
    
    private var emptyChildrenPrompt: some View {
        Text("Add at least two exercises to use this superset.")
            .font(AppFont.rowSubtitle)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
            .padding(.vertical, 10)
    }
    
    private var oneChildPrompt: some View {
        Text("Add one more exercise to use this superset.")
            .font(AppFont.rowSubtitle)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
            .padding(.vertical, 8)
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
    
    private func childRow(_ child: ExerciseModel) -> some View {
        HStack(spacing: 8) {
            Button {
                navigation.path.append(ExerciseListRoute.exerciseView(item: child))
            } label: {
                ExerciseRowContent(model: child,
                                   progressStatus: .none,
                                   iconSize: 58,
                                   minHeight: 78,
                                   showsProgress: false,
                                   showsIcon: true,
                                   contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 4))
            }
            .buttonStyle(.plain)
            
            if !viewModel.isActiveWorkoutLocked, viewModel.children.count > 1 {
                dragHandle
                    .padding(.trailing, 8)
                    .onDrag {
                        draggingChild = child
                        return NSItemProvider(object: child.id.uuidString as NSString)
                    }
                    .accessibilityLabel("Reorder")
            }
        }
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !viewModel.isActiveWorkoutLocked {
                Button {
                    viewModel.removeChild(child)
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
                .tint(.red)
                
                Button {
                    viewModel.hideChild(child)
                } label: {
                    Label("Hide", systemImage: "eye.slash")
                }
                .tint(AppColor.progressAmber)
            }
        }
    }
    
    private var dragHandle: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(AppColor.textSecondary)
                    .frame(width: 14, height: 2)
            }
        }
        .frame(width: 24, height: 44)
        .contentShape(Rectangle())
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

private extension View {
    func listRowStyle(top: CGFloat, bottom: CGFloat) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 20, bottom: bottom, trailing: 20))
            .listRowSeparator(.hidden)
            .listRowBackground(AppColor.backgroundPrimary)
    }
}

private struct SupersetChildDropDelegate: DropDelegate {
    let target: ExerciseModel
    @Binding var draggingChild: ExerciseModel?
    let moveAction: (UUID, UUID) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggingChild, draggingChild.id != target.id else { return }
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            moveAction(draggingChild.id, target.id)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggingChild = nil
        return true
    }
}
