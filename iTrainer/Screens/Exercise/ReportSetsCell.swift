//
//  ReportSetsCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 16.09.2024.
//

import SwiftUI

struct ReportSetsCell: View {
    
    enum Action {
        case selected(ReportSetsModel)
        case update(ReportSetsModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock?
    
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var colorEditButton: Color = AppColor.textSecondary
    
    var model: ReportSetsModel
    
    init(reportSet: ReportSetsModel, actionBlock: ActionBlock? = nil) {
        self.model = reportSet
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColor.progressGreen)
                .frame(width: 26, height: 26)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String.localizedStringWithFormat(String(localized: "exercise.set_number"), model.index))
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                
                Text(parametersText)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 6) {
                Text(model.date.formatted(date: .omitted, time: .shortened))
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                
                if actionBlock != nil {
                    Button(action: edit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(colorEditButton)
                            .frame(width: 34, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
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
            actionBlock?(.selected(model))
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
    
    private func edit() {
        colorEditButton = AppColor.textPrimary
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150)) {
            colorEditButton = AppColor.textSecondary
        }
        actionBlock?(.update(model))
    }
}

#Preview {
    ReportSetsCell(reportSet: ReportSetsModel(date: .now,
                                              params: [.weight(50), .repeats(8)]), actionBlock: {_ in })
        .environmentObject(AppSettings())
}
