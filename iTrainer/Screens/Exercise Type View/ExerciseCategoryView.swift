//
//  ExerciseCategoryView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import SwiftUI

struct ExerciseCategoryView: View {
    
    @StateObject var viewModel: ExerciseTypeViewModel
    
    @Environment(\.navigation) private var navigation
    
    init(viewModel: ExerciseTypeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.categories) { item in
                    categoryButton(for: item)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.backgroundPrimary)
            
            if viewModel.mode == .selecting {
                SelectExerciseBarView(countSelectedExercises: $viewModel.countSelectedExercises) {
                    viewModel.addExercise()
                } clearBlock: {
                    viewModel.clearSelectedExercise()
                }
            }
        }
        .background(AppColor.backgroundPrimary)
        .onAppear {
            viewModel.categoryId = nil
        }
    }
    
    private func categoryButton(for item: ExerciseCategory) -> some View {
        Button {
            viewModel.categoryId = item.id
            navigation.path.append(ExerciseTypeRoute.exerciseTypeListView(categoryId: item.id))
        } label: {
            ExerciseCategoryRow(
                category: item,
                exerciseCount: viewModel.exerciseCount(for: item)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ExerciseCategoryRow: View {
    
    let category: ExerciseCategory
    let exerciseCount: Int
    
    private let iconSize: CGFloat = 80
    
    var body: some View {
        HStack(spacing: 14) {
            category.icon
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category.displayName)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                
                Text(subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary.opacity(0.55))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private var subtitle: String {
        guard exerciseCount > 0 else { return "Coming next" }
        return "\(exerciseCount) exercises"
    }
}

#Preview {
    ExerciseCategoryView(viewModel: ExerciseTypeViewModel())
}
