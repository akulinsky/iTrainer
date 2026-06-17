//
//  ReportExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.09.2024.
//

import SwiftUI
import Charts

extension Date {
    func adding (_ component: Calendar.Component, value: Int, using calendar: Calendar = .current) -> Date? {
        return calendar.date(byAdding: component, value: value, to: self)
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}

struct DataPoint: Identifiable {
    let id: String
    let value: Double
}

enum LineChartType: String, CaseIterable, Plottable {
    case optimal = "Optimal"
    case outside = "Outside range"
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .outside: return .blue
        }
    }
}

struct LineChartData: Identifiable {
    
    var id = UUID()
    var date: Date
    var value: Double
    
    var type: LineChartType
}

var chartData2: [LineChartData] = {
    let sampleDate = Date().startOfDay.adding(.month, value: -10)!
    var temp = [LineChartData]()
    
    // Line 1
    for i in 0..<8 {
        let value = Double.random(in: 5...20)
        temp.append(
            LineChartData(
                date: sampleDate.adding(.month, value: i)!,
                value: value,
                type: .outside
            )
        )
    }
    
    // Line 2
    for i in 0..<8 {
        let value = Double.random(in: 5...20)
        temp.append(
            LineChartData(
                date: sampleDate.adding(.month, value: i)!,
                value: value,
                type: .optimal
            )
        )
    }
    
    return temp
}()

struct ReportExerciseView: View {
    
    let data = chartData2
    
    @ViewBuilder
    private var chart: some View {
        Chart {
            /*
            ForEach(data) { item in
                BarMark(
                    x: .value("Weekday", item.date),
                    y: .value("Value", item.value)
                )
                .position(by: .value("Performer", item.type), axis: .horizontal, span: .inset(15))
                
                .foregroundStyle(item.type.color)
                .foregroundStyle(by: .value("Plot", item.type))
            }
             */
            ForEach(viewModel.chartData) { item in
                BarMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
//                .position(by: .value("Performer", item.type), axis: .horizontal, span: .inset(10))
                .foregroundStyle(item.type.color)
                .foregroundStyle(by: .value("Plot", item.type))
            }
        }
        .frame(height: 300)
        .chartLegend(position: .bottom, alignment: .leading, spacing: 16){
            HStack(spacing: 6) {
                ForEach(ReportExerciseViewModel.ChartType.allCases, id: \.self) { type in
                    Circle()
                        .fill(type.color)
                        .frame(width: 8, height: 8)
                    Text(type.rawValue)
                        .foregroundStyle(type.color)
                        .font(.system(size: 11, weight: .medium))
                }
            }
        }
        .chartXAxis {
//            AxisMarks(preset: .extended, values: .stride(by: .month)) { value in
            AxisMarks(preset: .extended, values: .stride(by: .day)) { value in
//                AxisValueLabel(format: .dateTime.month())
                AxisValueLabel(format: .dateTime.day())
                
//                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
//                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
            }
        }
        .chartYAxis {
            AxisMarks(preset: .extended, position: .leading, values: .stride(by: 10))
        }
    }
    
    
    
    @StateObject var viewModel: ReportExerciseViewModel
    
    private var heightHeader: CGFloat = 50.0
    
    init(viewModel: ReportExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                
                VStack {
                    headerView
                        .frame(height: heightHeader)
//                        .padding([.top, .leading, .trailing])
                        .padding()
                    chart
                        .padding()
                }
                .listRowInsets(EdgeInsets.init(top: 0, leading: 0,
                                            bottom: 0, trailing: 0))
                reportSetsView
            }
            .listStyle(.plain)
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(viewModel.reportExercise.type?.type.title ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.reloadData()
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            if let icon = viewModel.reportExercise.type?.icon {
                icon
                    .resizable()
                    .frame(width: heightHeader)
            } else {
                Color.red.frame(width: heightHeader)
            }
            VStack {
                Text(viewModel.title).leadingAlignment()
            }
        }
    }
    
    @ViewBuilder
    private var reportSetsView: some View {
        ForEach(viewModel.sets) { item in
            ReportSetsCell(reportSet: item)
        }
    }
}

#Preview {
    ReportExerciseView(viewModel: ReportExerciseViewModel(reportExercise: ReportExerciseModel(titleExercise: "Title Exercise",
                                                                                              exerciseId: UUID(),
                                                                                              index: 1,
                                                                                              typeId: "type")))
}
