//
//  ExerciseCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct ExerciseCell: View {
    
    @State var model: ExerciseModel
    
    var body: some View {
        HStack {
            VStack {
                Text(model.title ?? "--").leadingAlignment()
            }
        }
        .frame(height: 60)
    }
}

#Preview {
    ExerciseCell(model: ExerciseModel(title: "TEST"))
}
