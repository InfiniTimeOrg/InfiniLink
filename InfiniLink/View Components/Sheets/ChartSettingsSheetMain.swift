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
    @AppStorage("dataRangeSelection") var dateRangeSelection: Int = 0
    @AppStorage("weeks") var weeks: Double = 0
    @AppStorage("days") var days: Double = 0
    @AppStorage("hours") var hours: Double = 1
    @AppStorage("startDate") var startDate: Date = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? (Date() - 2419200)
    @AppStorage("endDate") var endDate: Date = Date()
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
    var chartPoints: FetchedResults<ChartDataPoint>
    
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
                    Picker(NSLocalizedString("date_range_selection", comment: ""), selection: $dateRangeSelection) {
                        Text(NSLocalizedString("show_all", comment: "")).tag(0)
                        Text(NSLocalizedString("sliders", comment: "")).tag(1)
                        Text(NSLocalizedString("select_dates", comment: "")).tag(2)
                    }
                    .pickerStyle(.segmented)
                    switch dateRangeSelection {
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
                                Slider(value: $hours, in: 0...24, step: 1) {
                                    Text(NSLocalizedString("hours", comment: ""))
                                } minimumValueLabel: {
                                    Text(NSLocalizedString("hours", comment: "") + ": " + String(format: "%.0f", hours))
                                } maximumValueLabel: {
                                    Text("")
                                }
                                .modifier(RowModifier(style: .capsule))
                                
                                Slider(value: $days, in: 0...7, step: 1) {
                                    Text(NSLocalizedString("days", comment: ""))
                                } minimumValueLabel: {
                                    Text(NSLocalizedString("days", comment: "") + ": " + String(format: "%.0f", days))
                                } maximumValueLabel: {
                                    Text("")
                                }
                                .modifier(RowModifier(style: .capsule))
                                
                                Slider(value: $weeks, in: 0...4, step: 1) {
                                    Text(NSLocalizedString("weeks", comment: ""))
                                } minimumValueLabel: {
                                    Text(NSLocalizedString("weeks", comment: "") + ": " + String(format: "%.0f", weeks))
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
                                        selection: $startDate,
                                        in: (chartPoints[0].timestamp ?? oneMonthAgo)...today,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .modifier(RowModifier(style: .capsule))
                                    DatePicker(
                                        NSLocalizedString("end_date", comment: ""),
                                        selection: $endDate,
                                        in: startDate...today,
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
    }
}

#Preview {
    ChartSettingsSheet()
}
