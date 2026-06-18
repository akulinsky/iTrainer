//
//  ExerciseCategory.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 06.08.2024.
//

import Foundation
import SwiftUI

enum ExerciseCategory: Int, CaseIterable, Identifiable {
    
    case chest      // грудь
    case back       // спина
    case legs       // ноги
    case gluteus    // ягодичная мышца
    case deltoids   // дельтовидные мышцы
    case biceps     // Бицепс
    case triceps    // трицепс
    case forearm    // предплечье
    case press      // пресс
    case functionalWorkout  // функциональная тренировка
    case cardio     // кардио
    case stretching // растяжка
    
    var id: Int {
        self.rawValue
    }
    
    var title: String {
        switch self {
        case .chest:
            return "Грудь"
        case .back:
            return "Спина"
        case .legs:
            return "Ноги"
        case .gluteus:
            return "Ягодичная мышца"
        case .deltoids:
            return "Плечи"
        case .biceps:
            return "Бицепс"
        case .triceps:
            return "Трицепс"
        case .forearm:
            return "Предплечье"
        case .press:
            return "Пресс"
        case .functionalWorkout:
            return "Функциональная тренировка"
        case .cardio:
            return "Кардио"
        case .stretching:
            return "Растяжка"
        }
    }
    
    var icon: Image {
        switch self {
        case .chest:
            return Image("icMuscleType_chest")
        case .back:
            return Image("icMuscleType_chest")
        case .legs:
            return Image("icMuscleType_chest")
        case .gluteus:
            return Image("icMuscleType_chest")
        case .deltoids:
            return Image("icMuscleType_chest")
        case .biceps:
            return Image("icMuscleType_chest")
        case .triceps:
            return Image("icMuscleType_chest")
        case .forearm:
            return Image("icMuscleType_chest")
        case .press:
            return Image("icMuscleType_chest")
        case .functionalWorkout:
            return Image("icMuscleType_chest")
        case .cardio:
            return Image("icMuscleType_chest")
        case .stretching:
            return Image("icMuscleType_chest")
        }
    }
}
