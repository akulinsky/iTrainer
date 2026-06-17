//
//  ReportsViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 18.09.2024.
//

import Foundation

class ReportsViewModel: ObservableObject {
    
    // MARK: - properties
    
    @Published var reports = [ReportWorkoutModel]()
    
    @Published var isShowAlert = false
    
    @Published var selectedDate = Date() {
        didSet {
            reloadData()
        }
    }
    
    var errorMessage: String? = nil
    
    // MARK: - Private methods
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchAllReportWorkout().map { ReportWorkoutModel(model: $0) }
            await MainActor.run {
                reports = items.filter({
                    guard let start = $0.startDate, $0.endDate != nil else {
                        return false
                    }
                    return start >= selectedDate.beginningDay && start <= selectedDate.endingDay
                })
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
//    func setup() {
//        
//    }
    
    // MARK: - Public methods
    
    func reloadData(complete: (()->())? = nil) {
        self.fetchItems(complete: complete)
//        print("DBG_ beginning: \(Date.now.beginningDay.formatted(date: .abbreviated, time: .standard))")
//        print("DBG_ ending: \(Date.now.endingDay.formatted(date: .abbreviated, time: .standard))")
    }
    
    func refreshData() {
        
    }
}
