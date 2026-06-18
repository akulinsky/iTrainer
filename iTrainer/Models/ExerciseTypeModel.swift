//
//  ExerciseTypeModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 06.08.2024.
//

import Foundation
import SwiftUI

typealias SetsParameter = ParameterValue<Any>

enum ParameterValue<value>: Identifiable, Hashable {
    
    case repeats(_ value: Int = 0)
    case weight(_ value: Float = 0)
    case distance(_ value: Float = 0)
    case time(_ value: TimeInterval = 0)
    
    var title: String {
        switch self {
        case .weight(_):
            "Weight"
        case .repeats(_):
            "Reps"
        case .distance(_):
            "Distance"
        case .time(_):
            "Time"
        }
    }
    
    var stringValue: String {
        switch self {
        case .weight(let value):
            String(format: "%.1f", value)
        case .repeats(let value):
            "\(value)"
        case .distance(let value):
            value.distanceForDisplay
        case .time(let value):         
            value.timeForDisplay
        }
    }
    
    var id: Int {
        switch self {
        case .weight(_): 0
        case .repeats(_): 1
        case .distance(_): 2
        case .time(_): 3
        }
    }
    
    static func seedParameter(for id: String) -> ParameterValue<Any>? {
        switch id {
        case "weight":
            .weight()
        case "reps":
            .repeats()
        case "distance":
            .distance()
        case "time":
            .time()
        default:
            nil
        }
    }
}

struct ExerciseTypeModel: Identifiable {
    
    var id: String = UUID().uuidString
    
    let iconName: String
    let titleKey: String
    let defaultTitle: String
    let devTitle: String
    let type: ExerciseCategory
    let parameters: [ParameterValue<Any>]
    let sortOrder: Int
    var bookmark: Bool
    
    var icon: Image? {
        Image(iconName)
    }
    
    var title: String {
        displayName
    }
    
    var displayName: String {
        devTitle
    }
    
    init(id: String? = nil,
         titleKey: String = "",
         defaultTitle: String = "",
         devTitle: String,
         iconName: String = "ic_chest_exercise",
         type: ExerciseCategory,
         parameters: [ParameterValue<Any>],
         sortOrder: Int = 0,
         bookmark: Bool = false) {
        self.iconName = iconName
        self.titleKey = titleKey
        self.defaultTitle = defaultTitle
        self.devTitle = devTitle
        
        if let id = id {
            self.id = id
        }
        
        self.type = type
        self.parameters = parameters
        self.sortOrder = sortOrder
        self.bookmark = bookmark
    }
}

private struct ExerciseSeedModel: Decodable {
    let id: String
    let titleKey: String
    let defaultTitle: String
    let devTitle: String
    let category: String
    let iconName: String
    let parameters: [String]
    let sortOrder: Int
}

enum ExerciseSeedLoader {
    static func loadCategories() -> [ExerciseCategory] {
        load([ExerciseCategory].self, resource: "exercise_categories")
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }
    
    static func loadExercises(categories: [ExerciseCategory]? = nil) -> [ExerciseTypeModel] {
        let categories = categories ?? loadCategories()
        let categoryById = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let seeds = load([ExerciseSeedModel].self, resource: "exercises")
        
        return seeds.compactMap { seed in
            guard let category = categoryById[seed.category] else {
                assertionFailure("Missing exercise category with id: \(seed.category)")
                return nil
            }
            
            let parameters = seed.parameters.compactMap { ParameterValue<Any>.seedParameter(for: $0) }
            guard parameters.count == seed.parameters.count else {
                assertionFailure("Unsupported exercise parameters for id: \(seed.id)")
                return nil
            }
            
            return ExerciseTypeModel(id: seed.id,
                                     titleKey: seed.titleKey,
                                     defaultTitle: seed.defaultTitle,
                                     devTitle: seed.devTitle,
                                     iconName: seed.iconName,
                                     type: category,
                                     parameters: parameters,
                                     sortOrder: seed.sortOrder)
        }
        .sorted {
            if $0.type.sortOrder == $1.type.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.type.sortOrder < $1.type.sortOrder
        }
    }
    
    private static func load<T: Decodable>(_ type: T.Type, resource: String) -> T {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            fatalError("Missing bundled resource: \(resource).json")
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            fatalError("Failed to decode \(resource).json: \(error)")
        }
    }
}

extension ExerciseTypeModel {
    static var createExercises: [ExerciseTypeModel] {
        ExerciseSeedLoader.loadExercises()
    }
}
