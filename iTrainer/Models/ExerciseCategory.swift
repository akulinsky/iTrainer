//
//  ExerciseCategory.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 06.08.2024.
//

import Foundation
import SwiftUI

struct ExerciseCategory: Decodable, Identifiable, Equatable {
    let id: String
    let titleKey: String
    let defaultTitle: String
    let devTitle: String
    let kind: String
    let iconName: String
    let sortOrder: Int
    
    var title: String {
        displayName
    }
    
    var displayName: String {
        devTitle
    }
    
    var icon: Image {
        Image(iconName)
    }
}
