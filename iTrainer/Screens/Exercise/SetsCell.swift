//
//  SetsCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct SetsCell: View {
    
    @State var model: SetsModel
    
    var body: some View {
        HStack {
            Text("Weight: \(model.weight)")
            Text(" X ")
            Text("Reps: \(model.reps)")
        }
        .frame(height: 60)
    }
}

#Preview {
    SetsCell(model: SetsModel(reps: 10, weight: 100))
}
