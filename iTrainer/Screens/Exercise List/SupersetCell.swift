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
                emptyStateText(String(localized: "superset.prompt.two"))
            } else if children.count == 1 {
                childRows
                emptyStateText(String(localized: "superset.prompt.one_more"))
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
                SupersetPathIcon(dotCount: max(children.count, 1), rowHeight: 18, rowSpacing: 8)
                    .frame(width: 20)
                
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
            SupersetPathIcon(dotCount: children.count, rowHeight: 84, rowSpacing: 10)
                .frame(width: 20)
            
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
        return names.isEmpty ? String(localized: "superset.no_exercises") : names.joined(separator: " · ")
    }
    
}

private struct SupersetPathIcon: View {
    let dotCount: Int
    let rowHeight: CGFloat
    let rowSpacing: CGFloat
    
    private let dotSize: CGFloat = 12
    private let width: CGFloat = 20
    
    private var height: CGFloat {
        guard dotCount > 0 else { return rowHeight }
        return CGFloat(dotCount) * rowHeight + CGFloat(max(dotCount - 1, 0)) * rowSpacing
    }
    
    var body: some View {
        ZStack {
            if dotCount > 1 {
                Capsule()
                    .fill(AppColor.brandPrimary)
                    .frame(width: 3, height: CGFloat(dotCount - 1) * (rowHeight + rowSpacing))
                    .position(x: width / 2, y: height / 2)
            }
            
            ForEach(0..<max(dotCount, 1), id: \.self) { index in
                let y = rowHeight / 2 + CGFloat(index) * (rowHeight + rowSpacing)
                Circle()
                    .fill(AppColor.brandPrimary)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: width / 2, y: y)
            }
        }
        .frame(width: width, height: height)
    }
}
