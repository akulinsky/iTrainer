//
//  SetsCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct SetsCell: View {
    
    enum TargetStatus {
        case inactive
        case pending
        case completed
    }
    
    enum Action {
        case selected(SetsModel)
        case update(SetsModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var colorEditButton: Color = AppColor.textSecondary
    
    var model: SetsModel
    
    private let targetStatus: TargetStatus
    
    init(model: SetsModel,
         targetStatus: TargetStatus = .inactive,
         actionBlock: @escaping ActionBlock) {
        self.model = model
        self.targetStatus = targetStatus
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image("icTargetSet")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(targetIconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String.localizedStringWithFormat(String(localized: "exercise.set_number"), model.index))
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                
                Text(parametersText)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: edit) {
                Image(systemName: "pencil")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(colorEditButton)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minHeight: 58)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            actionBlock(.selected(model))
        }
    }
    
    private var parametersText: String {
        model.parameters.map(parameterText).joined(separator: " · ")
    }
    
    private var unitFormatter: UnitFormatter {
        UnitFormatter(settings: appSettings)
    }
    
    private func parameterText(_ parameter: SetsParameter) -> String {
        switch parameter {
        case .weight(let value):
            return unitFormatter.weightTextWithUnit(kilograms: value)
        case .distance(let value):
            return unitFormatter.distanceText(meters: value)
        case .repeats, .time:
            let unit = parameter.inlineUnitText
            return unit.isEmpty ? parameter.stringValue : "\(parameter.stringValue) \(unit)"
        }
    }
    
    private var targetIconColor: Color {
        switch targetStatus {
        case .inactive, .completed:
            AppColor.progressGreen
        case .pending:
            AppColor.progressAmber
        }
    }
    
    private func edit() {
        colorEditButton = AppColor.textPrimary
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150)) {
            colorEditButton = AppColor.textSecondary
        }
        actionBlock(.update(model))
    }
}

#Preview {
    SetsCell(model: SetsModel(params: [.weight(100), .repeats(10)])) { action in }
        .environmentObject(AppSettings())
}
