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
                        .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppColor.backgroundPrimary)
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleBookmarkFilter()
                } label: {
                    Image(systemName: viewModel.isBookmarkFilterEnabled ? "bookmark.fill" : "bookmark")
                }
                .foregroundStyle(viewModel.isBookmarkFilterEnabled ? AppColor.brandPrimary : AppColor.textSecondary)
                .accessibilityLabel(Text(viewModel.isBookmarkFilterEnabled ? "exercise_catalog.bookmarks.show_all" : "exercise_catalog.bookmarks.show_bookmarked"))
            }
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
    
    private let iconSize: CGFloat = 104
    private let cardCornerRadius: CGFloat = 16
    private let iconCornerRadius: CGFloat = 14
    
    var body: some View {
        HStack(spacing: 20) {
            category.icon
                .resizable()
                .scaledToFill()
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(category.displayName)
                    .font(AppFont.categoryCardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                
                Text(subtitle)
                    .font(AppFont.categoryCardSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(minHeight: 136)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var subtitle: String {
        guard exerciseCount > 0 else { return String(localized: "exercise_catalog.category.coming_next") }
        return String.localizedStringWithFormat(String(localized: "exercise_catalog.category.exercise_count"), exerciseCount)
    }
}

#Preview {
    ExerciseCategoryView(viewModel: ExerciseTypeViewModel())
}
