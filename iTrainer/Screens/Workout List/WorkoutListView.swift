//
//  WorkoutListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import SwiftUI
import SDWebImageSwiftUI

//Avatar
//https://randomuser.me/api/portraits/men/38.jpg

struct WorkoutListView: View {
    var body: some View {
        
        VStack {
            Text("The start")
            
            AnimatedImage(url: URL(string: "https://randomuser.me/api/portraits/men/38.jpg")) {
                Image("person_small")
            }
            .aspectRatio(contentMode: .fit)
            
            Text("Hello, World!")
        }
        .navigationTitle("iTrainer")
    }
}

#Preview {
    WorkoutListView()
}
