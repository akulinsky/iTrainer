//
//  SupersetExercisePickerView.swift
//  iTrainer
//
//  Created by Codex on 15.07.2026.
//

import SwiftUI

struct SupersetExercisePickerView: View {
    let exercises: [ExerciseModel]
    let onAdd: (Set<UUID>) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIds = Set<UUID>()
    
    var body: some View {
        NavigationStack {
            List {
                if exercises.isEmpty {
                    Text("No available exercises")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                } else {
                    ForEach(exercises) { exercise in
                        Button {
                            toggle(exercise.id)
                        } label: {
                            pickerCell(for: exercise)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.backgroundPrimary)
            .navigationTitle("Add exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        onAdd(selectedIds)
                        dismiss()
                    }
                    .font(AppFont.rowTitle)
                    .foregroundStyle(selectedIds.isEmpty ? AppColor.textSecondary : AppColor.brandPrimary)
                    .disabled(selectedIds.isEmpty)
                }
            }
        }
    }
    
    private func toggle(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
    
    private func pickerCell(for exercise: ExerciseModel) -> some View {
        HStack(spacing: 10) {
            ExerciseRowContent(model: exercise,
                               progressStatus: .none,
                               iconSize: 62,
                               minHeight: 84,
                               showsProgress: false,
                               showsIcon: true,
                               contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 2))
            
            Image(systemName: selectedIds.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(selectedIds.contains(exercise.id) ? AppColor.brandPrimary : AppColor.textSecondary)
                .frame(width: 30, height: 44)
                .padding(.trailing, 8)
        }
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}
