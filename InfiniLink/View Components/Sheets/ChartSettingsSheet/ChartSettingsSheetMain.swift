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
    @AppStorage("heartChartFill") var heartChartFill: Bool = true
    @AppStorage("batChartFill") var batChartFill: Bool = true
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
    var chartPoints: FetchedResults<ChartDataPoint>
    
    @State var chartRangeState: ChartManager.DateSelectionState = ChartManager.DateSelectionState(dateRangeSelection: 1)
    
    func setDateRange() {
        if chartManager.currentChart == .heart {
            chartManager.heartRangeSelectionState = chartRangeState
        } else {
            chartManager.batteryRangeSelectionState = chartRangeState
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                if chartManager.currentChart == .heart {
                    Text(NSLocalizedString("heart_rate_settings", comment: "Heart Rate Settings"))
                        .foregroundColor(.primary)
                        .font(.title.weight(.bold))
                } else {
                    Text(NSLocalizedString("battery_chart_settings", comment: "Battery Chart Settings"))
                        .foregroundColor(.primary)
                        .font(.title.weight(.bold))
                }
                Spacer()
                SheetCloseButton()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            VStack {
                VStack {
                    if chartManager.currentChart == .battery {
                        Toggle(NSLocalizedString("filled_battery_graph", comment: ""), isOn: $batChartFill)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                        Button (action: {
                            ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
                        }) {
                            Text(NSLocalizedString("clear_all_battery_chart_data", comment: ""))
                                .frame(maxWidth: .infinity)
                                .modifier(RowModifier(style: .capsule))
                        }
                    } else {
                        Toggle(NSLocalizedString("filled_hrm_graph", comment: ""), isOn: $heartChartFill)
                            .modifier(RowModifier(style: .capsule))
                        Button(action: {
                            ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
                        }) {
                            Text(NSLocalizedString("clear_all_hrm_chart_data", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.red)
                                .modifier(RowModifier(style: .capsule))
                        }
                    }
                    Divider()
                        .padding(.vertical, 10)
                        .padding(.horizontal, -16)
                }
                VStack {
                    Text(NSLocalizedString("select_date_range", comment: ""))
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                            .font(.title.weight(.bold))
                        Spacer()
                    case 1:
                        ChartSettingsSheetSliders(chartRangeState: self.$chartRangeState)
                    case 2:
                        if chartPoints.count < 1 {
                            Spacer()
                            Text(NSLocalizedString("insufficient_heart_rate_data", comment: ""))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .font(.title.weight(.bold))
                            Spacer()
                        } else {
                            ChartSettingsSheetDatePicker(chartRangeState: self.$chartRangeState, oldestPoint: chartPoints[0].timestamp)
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .padding()
        }
        .onDisappear {
            setDateRange()
        }
        .onAppear {
            if chartManager.currentChart == .heart {
                chartRangeState = chartManager.heartRangeSelectionState
            } else {
                chartRangeState = chartManager.batteryRangeSelectionState
            }
        }
    }
}

#Preview {
    ChartSettingsSheet()
}
