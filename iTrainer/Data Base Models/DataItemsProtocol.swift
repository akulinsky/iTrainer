//
//  DataItemsProtocol.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation

protocol ReportDataItemProtocol {
    var id: UUID { get }
    var title: String? { get }
    var startDate: Date? { get }
    var endDate: Date? { get }
}

protocol DataItemProtocol {
    var id: UUID { get }
    var index: Int { get }
    var title: String? { get }
}

protocol DataSetItemProtocol {
    var id: UUID { get }
    var index: Int { get }
}

protocol DataParamsProtocol {
    var reps: Int? { get }
    var weight: Float? { get }
    var distance: Float? { get }
    var time: TimeInterval? { get }
}
