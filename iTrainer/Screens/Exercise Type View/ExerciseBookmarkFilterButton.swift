//
//  ExerciseBookmarkFilterButton.swift
//  iTrainer
//
//  Created by Codex on 10.07.2026.
//

import SwiftUI

struct ExerciseBookmarkFilterButton: View {
    
    @ObservedObject var viewModel: ExerciseTypeViewModel
    
    var body: some View {
        Button {
            viewModel.toggleBookmarkFilter()
        } label: {
            Image(systemName: viewModel.isBookmarkFilterEnabled ? "bookmark.fill" : "bookmark")
        }
        .foregroundStyle(viewModel.isBookmarkFilterEnabled ? AppColor.brandPrimary : AppColor.textSecondary)
        .accessibilityLabel(Text(viewModel.isBookmarkFilterEnabled ? "exercise_catalog.bookmarks.show_all" : "exercise_catalog.bookmarks.show_bookmarked"))
    }
}
