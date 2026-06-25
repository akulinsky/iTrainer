//
//  DurationPickerSheet.swift
//  iTrainer
//

import SwiftUI

struct DurationPreset: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let seconds: Int
}

enum DurationPickerComponentMode {
    case automatic
    case minuteSecond
    case hourMinuteSecond
}

struct DurationPickerSheet: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let componentMode: DurationPickerComponentMode
    let minuteStep: Int
    let secondStep: Int
    let presets: [DurationPreset]
    let valueFormatter: (Int) -> String

    @Environment(\.dismiss) private var dismiss
    @State private var draftValue: Int

    init(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        componentMode: DurationPickerComponentMode = .automatic,
        minuteStep: Int = 1,
        secondStep: Int = 5,
        presets: [DurationPreset] = [],
        valueFormatter: @escaping (Int) -> String = { TimeInterval($0).timeForDisplay }
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.componentMode = componentMode
        self.minuteStep = max(1, minuteStep)
        self.secondStep = max(1, secondStep)
        self.presets = presets
        self.valueFormatter = valueFormatter
        self._draftValue = State(initialValue: Self.clamp(value.wrappedValue, to: range))
    }

    var body: some View {
        VStack(spacing: 22) {
            header
                .padding(.top, 24)

            if !presets.isEmpty {
                presetGrid
            }

            pickerView

            Text(valueFormatter(draftValue))
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.top, -4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 24)
        .background(AppColor.backgroundPrimary)
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textSecondary)

                Spacer()

                Button("Done") {
                    value = Self.clamp(draftValue, to: range)
                    dismiss()
                }
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.brandPrimary)
            }
        }
    }

    private var presetGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
            ForEach(presets) { preset in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        draftValue = Self.clamp(preset.seconds, to: range)
                    }
                } label: {
                    Text(preset.title)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(AppColor.surfacePrimary)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(AppColor.separatorSoft, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pickerView: some View {
        HStack(spacing: 0) {
            if showsHours {
                durationWheel(title: "hour", values: hourValues, selection: hourSelection)
            }

            durationWheel(title: "min", values: minuteValues, selection: minuteSelection)
            durationWheel(title: "sec", values: secondValues, selection: secondSelection, twoDigits: true)
        }
        .frame(height: 170)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }

    private func durationWheel(
        title: String,
        values: [Int],
        selection: Binding<Int>,
        twoDigits: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            Picker(title, selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(twoDigits ? String(format: "%02d", value) : "\(value)")
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()

            Text(title)
                .font(AppFont.durationPickerUnit)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, -14)
        }
        .frame(maxWidth: .infinity)
    }

    private var showsHours: Bool {
        switch componentMode {
        case .automatic:
            range.upperBound >= 3600
        case .minuteSecond:
            false
        case .hourMinuteSecond:
            true
        }
    }

    private var hourSelection: Binding<Int> {
        Binding(
            get: { draftValue / 3600 },
            set: { hour in
                let minutesAndSeconds = draftValue % 3600
                draftValue = Self.clamp(hour * 3600 + minutesAndSeconds, to: range)
            }
        )
    }

    private var minuteSelection: Binding<Int> {
        Binding(
            get: { showsHours ? (draftValue / 60) % 60 : draftValue / 60 },
            set: { minute in
                if showsHours {
                    draftValue = Self.clamp((draftValue / 3600) * 3600 + minute * 60 + draftValue % 60, to: range)
                } else {
                    draftValue = Self.clamp(minute * 60 + draftValue % 60, to: range)
                }
            }
        )
    }

    private var secondSelection: Binding<Int> {
        Binding(
            get: { draftValue % 60 },
            set: { second in
                draftValue = Self.clamp(draftValue - draftValue % 60 + second, to: range)
            }
        )
    }

    private var hourValues: [Int] {
        sortedUnique(Array(range.lowerBound / 3600...range.upperBound / 3600) + [draftValue / 3600])
    }

    private var minuteValues: [Int] {
        if showsHours {
            sortedUnique(Array(stride(from: 0, through: 59, by: minuteStep)) + [(draftValue / 60) % 60])
        } else {
            sortedUnique(Array(stride(from: range.lowerBound / 60, through: range.upperBound / 60, by: minuteStep)) + [draftValue / 60])
        }
    }

    private var secondValues: [Int] {
        sortedUnique(Array(stride(from: 0, through: 59, by: secondStep)) + [draftValue % 60])
    }

    private func sortedUnique(_ values: [Int]) -> [Int] {
        Array(Set(values)).sorted()
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

#Preview("Rest") {
    DurationPickerSheet(
        title: "Rest time",
        value: .constant(90),
        range: 0...600,
        presets: [
            DurationPreset(title: "0:30", seconds: 30),
            DurationPreset(title: "1:00", seconds: 60),
            DurationPreset(title: "1:30", seconds: 90),
            DurationPreset(title: "2:00", seconds: 120),
            DurationPreset(title: "3:00", seconds: 180),
            DurationPreset(title: "5:00", seconds: 300)
        ]
    )
}

#Preview("Target Time") {
    DurationPickerSheet(
        title: "Target time",
        value: .constant(20100),
        range: 0...21600,
        presets: [
            DurationPreset(title: "10 min", seconds: 600),
            DurationPreset(title: "30 min", seconds: 1800),
            DurationPreset(title: "1 hour", seconds: 3600),
            DurationPreset(title: "2 hours", seconds: 7200)
        ]
    )
}
