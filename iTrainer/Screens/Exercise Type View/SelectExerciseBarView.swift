//
//  SelectExerciseBarView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 16.08.2024.
//

import SwiftUI

struct SelectExerciseBarView: View {
    
    @Binding var countSelectedExercises: Int
    
    var addBlock: () -> Void
    var clearBlock: () -> Void
    
    private var isActionDisabled: Bool {
        countSelectedExercises == 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(String.localizedStringWithFormat(String(localized: "exercise_catalog.selected_count"), countSelectedExercises))
                .font(AppFont.rowTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                clearBlock()
            } label: {
                Image(systemName: "trash")
                    .font(.title3.weight(.semibold))
                    .frame(width: 42, height: 42)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.white)
            .opacity(isActionDisabled ? 0.45 : 1)
            .disabled(isActionDisabled)
            .buttonStyle(.plain)
            .accessibilityLabel(Text("exercise_catalog.clear_selection"))
            
            Button {
                addBlock()
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 42, height: 42)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.white)
            .opacity(isActionDisabled ? 0.45 : 1)
            .disabled(isActionDisabled)
            .buttonStyle(.plain)
            .accessibilityLabel(Text("common.add"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(AppColor.brandPrimary)
    }
}

#Preview {
    SelectExerciseBarView(countSelectedExercises: .constant(5), addBlock: {}, clearBlock: {})
}
