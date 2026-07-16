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
            
            if !viewModel.children.isEmpty {
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
            }
            
            childrenPrompt
                .listRowStyle(top: 2, bottom: 10)
            
            deleteButton
                .listRowStyle(top: 18, bottom: 24)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: viewModel.children.map(\.id))
        .dismissKeyboardOnTap()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("superset.edit.title")
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
                title: String(localized: "superset.rest.title"),
                value: restTimeSecondsBinding,
                range: 0...600,
                secondStep: 5,
                presets: restTimePresets
            )
            .presentationDetents([.height(430)])
            .presentationDragIndicator(.visible)
        }
        .alert(Text("superset.delete_alert.title"), isPresented: $viewModel.isDeleteConfirmationPresented) {
            Button("common.delete", role: .destructive) {
                viewModel.deleteSuperset {
                    dismiss()
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("superset.delete_alert.message")
        }
    }
    
    private var activeWorkoutLockedView: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.progressAmber)
                .frame(width: 24, height: 24)
            
            Text("superset.active_locked")
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
            Text("superset.exercises")
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
    
    private var childrenPrompt: some View {
        Text(childrenPromptText ?? String(localized: "superset.prompt.one_more"))
            .font(AppFont.rowSubtitle)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
            .padding(.vertical, 8)
            .opacity(childrenPromptText == nil ? 0 : 1)
            .accessibilityHidden(childrenPromptText == nil)
    }
    
    private var childrenPromptText: String? {
        if viewModel.children.isEmpty {
            return String(localized: "superset.prompt.two")
        }
        
        if viewModel.children.count == 1 {
            return String(localized: "superset.prompt.one_more")
        }
        
        return nil
    }
    
    private var titleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("common.name")
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
            
            Text("superset.name.keep_generated")
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
            Text("superset.rest_time")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            VStack(spacing: 14) {
                HStack {
                    Text("superset.rest_after_cycle")
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
                    .accessibilityLabel(Text("superset.reorder"))
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
                    Label("superset.remove", systemImage: "minus.circle")
                }
                .tint(.red)
                
                Button {
                    viewModel.hideChild(child)
                } label: {
                    Label("common.hide", systemImage: "eye.slash")
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
            Text("superset.delete_button")
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
