//
//  EditSetsView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 02.08.2024.
//

import SwiftUI
import Combine

struct EditSetsView: View {
    
    @Observable
    class ParamData: Identifiable {
        var id: Int
        var value: String = ""
        var shake = PassthroughSubject<Void, Never>()
        
        let param: SetsParameter
        
        let keyboardType: UIKeyboardType
        
        init(param: SetsParameter) {
            self.param = param
            self.id = param.id
            
            switch param {
            case .weight(let value):
                if value > 0 {
                    self.value = "\(value)"
                }
                keyboardType = .decimalPad
            case .repeats(let value):
                if value > 0 {
                    self.value = "\(value)"
                }
                keyboardType = .numberPad
            case .distance(let value):
                if value > 0 {
                    self.value = value.distanceForDisplay
                }
                keyboardType = .numberPad
            case .time(let value):
                if value > 0 {
                    self.value = value.timeForTextField
                }
                keyboardType = .numberPad
            }
        }
    }
    
    enum Result {
        case save(params: [SetsParameter])
        case cancel
    }
    
    typealias ResultBlock = (Result)->()
    
    @State private var params  = [ParamData]()
    
    @State private var setsParams: [SetsParameter] = []
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @Environment(\.colorScheme) var colorScheme
    
    private var shakeReps = PassthroughSubject<Void, Never>()
    private var shakeWeight = PassthroughSubject<Void, Never>()
    
    private var title: String
    
    private var complete: ResultBlock
    
    init(title: String = "",
         params: [SetsParameter] = [],
         complete: @escaping ResultBlock = {_ in }) {
        
        self.title = title
        self.complete = complete
        _setsParams = State(initialValue: params)
        
        var result  = [ParamData]()
        for param in params {
            let data = ParamData(param: param)
            result.append(data)
        }
        _params = State(initialValue: result)
    }
    
    private var color: Color {
        switch colorScheme {
        case .light:
            Color(UIColor.darkGray)
        default:
            Color(UIColor.lightGray)
        }
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 30) {
                
                ForEach(self.$params) { $item in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(item.param.title)")
                                    .font(.caption)
                            
                        }
                        .frame(height: 30)
                        .padding([.leading, .trailing])
                        .foregroundStyle(.gray)
                        
                        HStack {
                            TextField(item.param.title, text: $item.value, onEditingChanged: { focused in
                                self.focused(focused, param: item)
                            })
                            .textFieldStyle(AKTextFieldStyle())
                            .shakeAnimation(item.shake)
                            .keyboardType(item.keyboardType)
//                            .foregroundStyle(color)
                        }
                    }
                }
            }
            .padding([.leading, .trailing], 30)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        cancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        prepareToSave()
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func focused(_ focused: Bool, param: ParamData) {
        if focused {
            return
        }
        
        switch param.param {
        case .time(_):
            let value = param.value.replacingOccurrences(of: ":", with: "")
            if let value = Double(value), value > 0 {
                let time = TimeInterval.timeForSet(value: value)
                DispatchQueue.main.async {
                    param.value = time.timeForTextField
                }
            }
           
        default:
            break
        }
    }
    
    private func prepareToSave() {
        
        var result = [SetsParameter]()
        
        for param in params {
            switch param.param {
            case .weight(_):
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                if let value = numberFormatter.number(from: param.value)?.floatValue, value > 0 {
                    result.append(.weight(value))
                } else if let value = Float(param.value), value > 0 {
                    result.append(.weight(value))
                } else {
                    param.shake.send()
                    return
                }
            case .repeats(_):
                if let value = Int(param.value), value > 0 {
                    result.append(.repeats(value))
                } else {
                    param.shake.send()
                    return
                }
            case .distance(_):
                if let value = Float(param.value), value > 0 {
                    result.append(.distance(value))
                } else {
                    param.shake.send()
                    return
                }
            case .time(_):
                let value = param.value.replacingOccurrences(of: ":", with: "")
                if let value = Double(value), value > 0 {
                    let time = TimeInterval.timeForSet(value: value)
                    result.append(.time(time))
                } else {
                    param.shake.send()
                    return
                }
            }
        }
        complete(.save(params: result))
        presentationMode.wrappedValue.dismiss()
    }
    
    private func cancel() {
        complete(.cancel)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EditSetsView(title: "Add new sets", params: [.weight(100), .repeats(10)]) { result in }
}
