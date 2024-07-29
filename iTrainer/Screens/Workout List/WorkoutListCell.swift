//
//  WorkoutListCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct WorkoutListCell: View {
    
    @State var model: WorkoutModel
    
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
    WorkoutListCell(model: WorkoutModel(title: "TEST"))
}
