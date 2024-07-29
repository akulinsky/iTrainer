//
//  ContentView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    var body: some View {
//        NavigationSplitView {
//            WorkoutListView()
//        } detail: {
//            Text("Select an item")
//        }
        NavigationStack {
            WorkoutListView()
        }
    }
}

#Preview {
    ContentView()
}
