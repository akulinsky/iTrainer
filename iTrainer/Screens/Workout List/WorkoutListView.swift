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
    
    @StateObject var viewModel = WorkoutListViewModel()
    
    var body: some View {
        
        VStack {
            List {
                ForEach(viewModel.workouts) { item in
                    NavigationLink {
                        WorkoutGroupListView(viewModel: WorkoutGroupListViewModel(workout: item))
                        
                    } label: {
                        WorkoutListCell(model: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .refreshable {
                refresh()
            }
        }
        .navigationTitle("Workouts")
        .task {
            viewModel.reloadData {
                if viewModel.workouts.count == 0 {
                    refresh()
                }
            }
        }
    }
    
    private func refresh() {
        viewModel.refreshData()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
//            for index in offsets {
//                viewModel.delete(index: index)
//            }
        }
    }
}

#Preview {
    WorkoutListView()
}
