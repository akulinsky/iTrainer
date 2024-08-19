//
//  ExerciseTypeModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 06.08.2024.
//

import Foundation
import SwiftUI

enum ParameterValue<value> {
    case repeats(_ value: Int = 0)
    case weight(_ value: Float = 0)
    case distance(_ value: Float = 0)
    case timer(_ value: TimeInterval = 0)
}

//enum ParameterValue<T>: CaseIterable {
//enum ParameterType: Int, CaseIterable {
//    case repeats
//    case weight
//    case distance
//    case timer
//}

struct ExerciseTypeModel: Identifiable {
    
    var id: String = UUID().uuidString
    
    let icon: Image?
    let title: String
    let type: MuscleType
    let parameters: [ParameterValue<Any>]
    var bookmark: Bool
    
    init(id: String? = nil, title: String, icon: Image? = nil, type: MuscleType, parameters: [ParameterValue<Any>], bookmark: Bool = false) {
//        self.icon = icon
        self.icon = Image("ic_chest_exercise")
        
        if let id = id {
            self.id = id
        }
        
        self.title = title
        self.type = type
        self.parameters = parameters
        self.bookmark = bookmark
    }
}

extension ExerciseTypeModel {
    static var createExercises: [ExerciseTypeModel] {
        var result = createChestExercises
        result.append(contentsOf: createBackExercises)
        result.append(contentsOf: createLegsExercises)
        
        return result
    }
    
    static var createChestExercises: [ExerciseTypeModel] {
        return [
            ExerciseTypeModel(id: "0",
                              title: "Жим лежа",
                              type: .chest,
                              parameters: [.weight(), .repeats()]
                             ),
            ExerciseTypeModel(id: "2",
                              title: "Жим лежа на наклонной скамье",
                              type: .chest,
                              parameters: [.weight(), .repeats()]
                             )
        ]
    }
    
    static var createBackExercises: [ExerciseTypeModel] {
        return [
            ExerciseTypeModel(id: "200",
                              title: "Тяга штанги в наклоне",
                              type: .back,
                              parameters: [.weight(), .repeats()]
                             ),
            ExerciseTypeModel(id: "201",
                              title: "Подтягивание на перекладине",
                              type: .back,
                              parameters: [.weight(), .repeats()]
                             )
        ]
    }
    
    static var createLegsExercises: [ExerciseTypeModel] {
        return [
            ExerciseTypeModel(id: "400",
                              title: "Приседание со штангой",
                              type: .legs,
                              parameters: [.weight(), .repeats()]
                             ),
            ExerciseTypeModel(id: "401",
                              title: "Еще упражнение на ноги",
                              type: .legs,
                              parameters: [.weight(), .repeats()]
                             )
        ]
    }
}

