//
//  WorkoutGroupCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct WorkoutGroupCell: View {
    
    @State var model: WorkoutGroupModel
    
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
    WorkoutGroupCell(model: WorkoutGroupModel(title: "TEST"))
}
