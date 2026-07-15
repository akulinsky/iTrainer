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
                            HStack(spacing: 12) {
                                Image(systemName: selectedIds.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(selectedIds.contains(exercise.id) ? AppColor.brandPrimary : AppColor.textSecondary)
                                    .frame(width: 28)
                                
                                ExerciseTypeIconView(exerciseType: exercise.type,
                                                     size: 56,
                                                     cornerRadius: 10)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(exercise.displayName)
                                        .font(AppFont.rowTitle)
                                        .foregroundStyle(AppColor.textPrimary)
                                        .lineLimit(1)
                                    
                                    if let type = exercise.type {
                                        Text(type.type.displayName)
                                            .font(AppFont.rowSubtitle)
                                            .foregroundStyle(AppColor.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
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
}
