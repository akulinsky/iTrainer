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
        var distanceUnit: DistanceInputUnit = .meters
        var weightUnit: ResolvedWeightUnit = .kilograms
        
        var unitText: String {
            switch param {
            case .weight:
                weightUnit.symbol
            case .distance:
                distanceUnit.title
            default:
                param.unitText
            }
        }
        
        var isDistance: Bool {
            if case .distance = param {
                return true
            }
            return false
        }
        
        let keyboardType: UIKeyboardType
        
        func applyUnitFormatter(_ formatter: UnitFormatter) {
            switch param {
            case .weight(let value):
                weightUnit = formatter.weightUnit
                if value > 0 {
                    self.value = formatter.weightText(kilograms: value)
                }
            case .distance(let value):
                if value > 0 {
                    let unit = DistanceInputUnit.preferred(forMeters: value, distanceUnit: formatter.distanceUnit)
                    distanceUnit = unit
                    self.value = unit.textValue(forMeters: value)
                } else {
                    distanceUnit = DistanceInputUnit.units(for: formatter.distanceUnit).first ?? .meters
                }
            default:
                break
            }
        }
        
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
                    let unit = DistanceInputUnit.preferred(forMeters: value)
                    distanceUnit = unit
                    self.value = unit.textValue(forMeters: value)
                }
                keyboardType = .decimalPad
            case .time(let value):
                if value > 0 {
                    self.value = value.timeForTextField
                }
                keyboardType = .numberPad
            }
            
            applyUnitFormatter(UnitFormatter(settings: AppSettings.shared))
        }
    }
    
    enum Result {
        case save(params: [SetsParameter])
        case cancel
    }
    
    typealias ResultBlock = (Result)->()
    
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var params  = [ParamData]()
    
    @State private var didApplyUnitPreferences = false
    
    @State private var setsParams: [SetsParameter] = []
    
    @FocusState private var focusedParamId: Int?
    
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
    
    private var unitFormatter: UnitFormatter {
        UnitFormatter(settings: appSettings)
    }
    
    private var distanceInputUnits: [DistanceInputUnit] {
        DistanceInputUnit.units(for: unitFormatter.distanceUnit)
    }
    
    private var focusedDistanceParam: ParamData? {
        guard let focusedParamId else {
            return nil
        }
        return params.first { $0.id == focusedParamId && $0.isDistance }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                HStack(spacing: 12) {
                    ForEach(self.$params) { $item in
                        parameterInput(item: $item)
//                            .frame(width: 74)
                            .frame(width: 110)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(16)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColor.separatorSoft, lineWidth: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
            .background(AppColor.backgroundPrimary)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") {
                        cancel()
                    }
                    .foregroundStyle(AppColor.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        prepareToSave()
                    }
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.brandPrimary)
                }
            }
            .keyboardAccessory(isPresented: focusedParamId != nil,
                               onClear: clearFocusedInput,
                               onDone: { focusedParamId = nil }) {
                if let focusedDistanceParam {
                    DistanceUnitPicker(selectedUnit: focusedDistanceParam.distanceUnit,
                                       units: distanceInputUnits,
                                       onSelect: setFocusedDistanceUnit)
                }
            }
        }
        .onAppear(perform: applyUnitPreferencesIfNeeded)
    }
    
    private func applyUnitPreferencesIfNeeded() {
        guard !didApplyUnitPreferences else {
            return
        }
        
        didApplyUnitPreferences = true
        params.forEach { $0.applyUnitFormatter(unitFormatter) }
    }
    
    private func parameterInput(item: Binding<ParamData>) -> some View {
        VStack(spacing: 6) {
            Text(item.wrappedValue.param.title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
            
            ZStack {
                TextField(item.wrappedValue.param.title, text: item.value, onEditingChanged: { focused in
                    self.focused(focused, param: item.wrappedValue)
                })
                .textFieldStyle(.plain)
                .font(AppFont.rowTitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shakeAnimation(item.wrappedValue.shake)
                .keyboardType(item.wrappedValue.keyboardType)
                .focused($focusedParamId, equals: item.wrappedValue.id)
                .onChange(of: item.wrappedValue.value) { _, newValue in
                    sanitizeDistanceInput(item: item, value: newValue)
                }
            }
            .frame(height: 48)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedParamId = item.wrappedValue.id
            }
            .background(AppColor.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            
            Text(item.wrappedValue.unitText)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 18)
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
    
    private func clearFocusedInput() {
        guard let focusedParamId,
              let param = params.first(where: { $0.id == focusedParamId }) else {
            return
        }
        
        param.value = ""
    }
    
    private func sanitizeDistanceInput(item: Binding<ParamData>, value: String) {
        guard item.wrappedValue.isDistance else {
            return
        }
        
        let sanitizedValue = item.wrappedValue.distanceUnit.sanitizedInputText(value)
        if sanitizedValue != value {
            item.wrappedValue.value = sanitizedValue
        }
    }
    
    private func setFocusedDistanceUnit(_ unit: DistanceInputUnit) {
        guard let param = focusedDistanceParam,
              param.distanceUnit != unit else {
            return
        }
        
        param.value = unit.convertedText(from: param.value, previousUnit: param.distanceUnit)
        param.distanceUnit = unit
    }
    
    private func parsedFloat(from text: String) -> Float? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        if let value = numberFormatter.number(from: text)?.floatValue {
            return value
        }
        return DistanceInputUnit.inputValue(from: text)
    }
    
    private func prepareToSave() {
        
        var result = [SetsParameter]()
        
        for param in params {
            switch param.param {
            case .weight(_):
                if let value = parsedFloat(from: param.value), value > 0 {
                    result.append(.weight(unitFormatter.kilograms(fromInputValue: value)))
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
                if let value = DistanceInputUnit.inputValue(from: param.value), value > 0 {
                    result.append(.distance(param.distanceUnit.meters(fromInputValue: value)))
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
        .environmentObject(AppSettings())
}
