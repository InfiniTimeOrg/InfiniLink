//
//  ChartSettingsSheet.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/13/21.
//
//


import SwiftUI

struct ChartSettingsSheet: View {
    let chartManager = ChartManager.shared
    let today = Date()
    let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? (Date() - 2419200)
    
    @AppStorage("heartChartFill") var heartChartFill: Bool = true
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
    var chartPoints: FetchedResults<ChartDataPoint>
    
    @State var chartRangeState: ChartManager.DateSelectionState = ChartManager.DateSelectionState(dateRangeSelection: 1)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Text(NSLocalizedString("heart_rate_settings", comment: "Heart Rate Settings"))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            VStack {
                VStack {
                    Picker(NSLocalizedString("date_range_selection", comment: ""), selection: $chartRangeState.dateRangeSelection) {
                        Text(NSLocalizedString("show_all", comment: "")).tag(0)
                        Text(NSLocalizedString("sliders", comment: "")).tag(1)
                        Text(NSLocalizedString("select_dates", comment: "")).tag(2)
                    }
                    .pickerStyle(.segmented)
                    switch chartRangeState.dateRangeSelection {
                    case 0:
                        Spacer()
                        Text(NSLocalizedString("all_data_selected", comment: ""))
                            .frame(maxWidth: .infinity)
                            .font(.title2.weight(.medium))
                            .foregroundColor(.gray)
                        Spacer()
                    case 1:
                        ScrollView {
                            VStack {
                                Slider(value: $chartRangeState.hours, in: 0...24, step: 1) {
                                    Text(NSLocalizedString("hours", comment: ""))
                                } minimumValueLabel: {
                                    Text(NSLocalizedString("hours", comment: "") + ": " + String(format: "%.0f", chartRangeState.hours))
                                } maximumValueLabel: {
                                    Text("")
                                }
                                .modifier(RowModifier(style: .capsule))
                                
                                Slider(value: $chartRangeState.days, in: 0...7, step: 1) {
                                    Text(NSLocalizedString("days", comment: ""))
                                }  minimumValueLabel: {
                                    Text(NSLocalizedString("days", comment: "") + ": " + String(format: "%.0f", chartRangeState.days))
                                } maximumValueLabel: {
                                    Text("")
                                }
                                .modifier(RowModifier(style: .capsule))
                                
                                Slider(value: $chartRangeState.weeks, in: 0...4, step: 1) {
                                    Text(NSLocalizedString("weeks", comment: ""))
                                }  minimumValueLabel: {
                                    Text(NSLocalizedString("weeks", comment: "") + ": " + String(format: "%.0f", chartRangeState.weeks))
                                } maximumValueLabel: {
                                    Text("")
                                }
                                .modifier(RowModifier(style: .capsule))
                            }
                            .padding(.top, 8)
                        }
                    case 2:
                        if chartPoints.count < 1 {
                            Spacer()
                            Text(NSLocalizedString("insufficient_heart_rate_data", comment: ""))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .font(.title.weight(.bold))
                            Spacer()
                        } else {
                            ScrollView {
                                VStack {
                                    DatePicker(
                                        NSLocalizedString("start_date", comment: ""),
                                        selection: $chartRangeState.startDate,
                                        in: (chartPoints[0].timestamp ?? oneMonthAgo)...today,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .modifier(RowModifier(style: .capsule))
                                    DatePicker(
                                        NSLocalizedString("end_date", comment: ""),
                                        selection: $chartRangeState.endDate,
                                        in: chartRangeState.startDate...today,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .modifier(RowModifier(style: .capsule))
                                }
                                .padding(.top, 8)
                            }
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .padding()
        }
        .onDisappear {
            chartManager.heartRangeSelectionState = chartRangeState
        }
        .onAppear {
            chartRangeState = chartManager.heartRangeSelectionState
        }
    }
}

#Preview {
    ChartSettingsSheet()
}
