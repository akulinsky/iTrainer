//
//  ReportExerciseCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 20.09.2024.
//

import SwiftUI

struct ReportExerciseCell: View {
    
    var model: ReportExerciseModel
    
    @Environment(\.editMode) var editMode
    
    init(model: ReportExerciseModel) {
        self.model = model
    }
    
    private var heightCell: CGFloat {
        return 60
    }
    
    private var detail: String {
        
        var weight: Float?
        var reps: Int?
        var distance: Float?
        var time: TimeInterval?
        
        for set in model.sets {
            set.parameters.forEach { param in
                switch param {
                case .weight(let value):
                    var repsTmp: Int?
                    set.parameters.forEach({
                        switch $0 {
                        case .repeats(let value):
                            repsTmp = value
                        default:
                            break
                        }
                    })
                    
                    if let reps = repsTmp {
                        weight = (weight ?? 0) + (value * Float(reps))
                    } else {
                        weight = (weight ?? 0) + value
                    }
                case .repeats(let value):
                    reps = (reps ?? 0) + value
                case .distance(let value):
                    distance = (distance ?? 0) + value
                case .time(let value):
                    time = (time ?? 0) + value
                }
            }
        }
        
        var result = ""
        
        if let weight = weight {
            result = "\(SetsParameter.weight().title): \(weight)"
        }
        
        if let reps = reps {
            if !result.isEmpty {
                result += "\n"
            }
            result += "\(SetsParameter.repeats().title): \(reps)"
        }
        
        if let distance = distance {
            if !result.isEmpty {
                result += "\n"
            }
            result += "\(SetsParameter.distance().title): \(distance)"
        }
        
        if let time = time {
            if !result.isEmpty {
                result += "\n"
            }
            result += "\(SetsParameter.time().title): \(time.timeForDisplay)"
        }
        
        return result
    }
    
    var body: some View {
        HStack {
            if let icon = model.type?.icon {
                icon
                    .resizable()
                    .frame(width: heightCell)
            } else {
                Color.red.frame(width: heightCell)
            }
            VStack(alignment: .leading) {
                Text(model.titleExercise)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .font(.subheadline)
                    .fixedSize()
            }
        }
        .frame(height: heightCell)
    }
}

#Preview {
    ReportExerciseCell(model: ReportExerciseModel(titleExercise: "Title",
                                                  exerciseId: UUID(),
                                                  index: 1, typeId: ""))
}
