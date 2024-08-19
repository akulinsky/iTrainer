//
//  DataItemsProtocol.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation

protocol DataItemProtocol {
    var id: UUID { get }
    var index: Int { get }
    var title: String? { get }
}

protocol DataSetItemProtocol {
    var id: UUID { get }
    var index: Int { get }
    var reps: Int? { get }
    var weight: Float? { get }
    var distance: Float? { get }
    var timer: Date? { get }
}
