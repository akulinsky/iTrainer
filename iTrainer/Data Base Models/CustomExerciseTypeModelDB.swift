//
//  CustomExerciseTypeModelDB.swift
//  iTrainer
//
//  Created by Codex on 09.07.2026.
//

import Foundation
import SwiftData

@Model
final class CustomExerciseTypeModelDB {
    @Attribute(.unique) var id: String
    var title: String
    var categoryId: String
    var trackingTypeId: String
    var descriptionText: String?
    var iconSystemName: String
    var sortOrder: Int
    var createdAt: Date
    
    init(id: String,
         title: String,
         categoryId: String,
         trackingTypeId: String,
         descriptionText: String? = nil,
         iconSystemName: String,
         sortOrder: Int,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
        self.trackingTypeId = trackingTypeId
        self.descriptionText = descriptionText
        self.iconSystemName = iconSystemName
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
