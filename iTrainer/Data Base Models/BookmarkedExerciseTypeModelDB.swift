//
//  BookmarkedExerciseTypeModelDB.swift
//  iTrainer
//
//  Created by OpenAI on 10.07.2026.
//

import Foundation
import SwiftData

@Model
final class BookmarkedExerciseTypeModelDB {
    @Attribute(.unique) var typeId: String
    var createdAt: Date
    
    init(typeId: String, createdAt: Date = Date()) {
        self.typeId = typeId
        self.createdAt = createdAt
    }
}
