//
//  ExerciseTypeCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import SwiftUI

struct ExerciseTypeCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    private var model: ExerciseTypeModel
    
    private let mode: ExerciseTypeViewMode
    
    private let isSelected: Bool
    
    private let frameSize: CGFloat = 80
    
    private var color: Color {
        
        switch colorScheme {
        case .light:
            isSelected ? Color(UIColor.darkGray) : Color(UIColor.lightGray).opacity(0.5)
        default:
            isSelected ? Color(UIColor.lightGray) : Color(UIColor.darkGray).opacity(0.5)
        }
    }
    
    var toggleBlock: ()->()
    
    init(model: ExerciseTypeModel, mode: ExerciseTypeViewMode, isSelected: Bool, toggleBlock: @escaping ()->()) {
        self.model = model
        self.mode = mode
        self.isSelected = isSelected
        self.toggleBlock = toggleBlock
    }
    
    var body: some View {
        HStack {
            
            if mode == .selecting {
                Image(systemName: "checkmark.circle")
                    .font(.title)
                    .foregroundStyle(color)
                    .onTapGesture {
                        toggleBlock()
                    }
            }
            
            if let icon = model.icon {
                icon
                    .resizable()
                    .frame(width: frameSize)
            } else {
                Color.red.frame(width: frameSize)
            }
            Text(model.title).leadingAlignment()
        }
        .frame(height: frameSize)
    }
}

#Preview {
    let category = ExerciseCategory(id: "chest",
                                    titleKey: "exercise.category.chest",
                                    defaultTitle: "Chest",
                                    devTitle: "Грудь",
                                    kind: "muscleGroup",
                                    iconName: "icMissingImage",
                                    sortOrder: 0)
    ExerciseTypeCell(model: ExerciseTypeModel(devTitle: "Жим лежа",
                                              type: category,
                                              parameters: [.weight(), .repeats()]
                                             ),
                     mode: .showing,
                     isSelected: false,
                     toggleBlock: {})
}
