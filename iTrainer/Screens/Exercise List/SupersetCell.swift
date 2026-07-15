//
//  SupersetCell.swift
//  iTrainer
//
//  Created by Codex on 15.07.2026.
//

import SwiftUI

struct SupersetCell: View {
    enum Action {
        case edit(ExerciseModel)
        case openChild(ExerciseModel)
    }
    
    let model: ExerciseModel
    let editMode: EditMode
    let progressStatus: (ExerciseModel) -> ExerciseProgressStatus
    let action: (Action) -> Void
    
    private var children: [ExerciseModel] {
        model.sortedSupersetExercises
    }
    
    var body: some View {
        if editMode == .active {
            compactEditCell
        } else {
            expandedCell
        }
    }
    
    private var expandedCell: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            
            if children.isEmpty {
                emptyStateText("Add at least two exercises to use this superset.")
            } else if children.count == 1 {
                childRows
                emptyStateText("Add one more exercise to use this superset.")
            } else {
                childRows
            }
        }
        .padding(14)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var compactEditCell: some View {
        Button {
            action(.edit(model))
        } label: {
            HStack(spacing: 14) {
                SupersetPathIcon(height: 34)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    
                    Text(childNamesText)
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 70)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            Text(model.displayName)
                .font(AppFont.workoutGroupCardTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            
            Spacer(minLength: 8)
            
            Button {
                action(.edit(model))
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColor.separatorSoft, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action(.edit(model))
        }
    }
    
    private var childRows: some View {
        HStack(alignment: .top, spacing: 12) {
            SupersetPathIcon(height: childConnectorHeight)
                .frame(width: 32)
                .padding(.top, 28)
            
            VStack(spacing: 10) {
                ForEach(children) { child in
                    Button {
                        action(.openChild(child))
                    } label: {
                        ExerciseRowContent(model: child,
                                           progressStatus: progressStatus(child),
                                           iconSize: 62,
                                           minHeight: 84,
                                           showsProgress: true,
                                           showsIcon: true,
                                           contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 8))
                            .background(AppColor.backgroundPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColor.separatorSoft, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func emptyStateText(_ text: String) -> some View {
        Text(text)
            .font(AppFont.rowSubtitle)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
    }
    
    private var childNamesText: String {
        let names = children.map(\.displayName).filter { !$0.isEmpty }
        return names.isEmpty ? "No exercises" : names.joined(separator: " · ")
    }
    
    private var childConnectorHeight: CGFloat {
        guard children.count > 1 else { return 32 }
        return CGFloat(children.count - 1) * 94 + 32
    }
}

private struct SupersetPathIcon: View {
    let height: CGFloat
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(AppColor.brandPrimary)
                .frame(width: 3, height: max(height - 16, 12))
            
            VStack {
                Circle()
                    .fill(AppColor.brandPrimary)
                    .frame(width: 12, height: 12)
                Spacer(minLength: 0)
                Circle()
                    .fill(AppColor.brandPrimary)
                    .frame(width: 12, height: 12)
            }
            .frame(height: height)
        }
    }
}
