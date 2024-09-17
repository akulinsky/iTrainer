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
    
    private var actionBlock: ActionBlock
    
    @State private var colorEditButton: Color = .gray
    
    var model: ReportSetsModel
    
    init(reportSet: ReportSetsModel, actionBlock: @escaping ActionBlock) {
        self.model = reportSet
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            Text("# \(model.index):")
                .font(.footnote)
                .bold()
            
            ForEach(model.parameters) { item in
                Text("\(item.title):")
                    .font(.footnote)
                Text(item.stringValue).bold()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Image(systemName: "pencil")
                    .foregroundStyle(colorEditButton)
                    .font(.title2)
                    .frame(maxWidth: 50, maxHeight: .infinity, alignment: .trailing)
                    .onTapGesture {
                        colorEditButton = Color(UIColor.darkGray)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150)) {
                            colorEditButton = .gray
                        }
                        actionBlock(.update(model))
                    }
            }
        }
        .foregroundStyle(.gray)
        .frame(height: 30)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .onTapGesture {
            actionBlock(.selected(model))
        }
        .listRowBackground(Color(uiColor: .systemGray6))
    }
}

#Preview {
    ReportSetsCell(reportSet: ReportSetsModel(date: Date()), actionBlock: {_ in })
}
