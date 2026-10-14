//
//  BatteryChartView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on May 17th 2026.
//

import SwiftUI
import Charts

struct BatteryChartDataPoint: Identifiable {
    var id = UUID()
    let date: Date
    let value: Double
}

struct BatteryChartView: View {
    @ObservedObject var bleManager = BLEManager.shared

    @State private var points = [BatteryChartDataPoint]()
    @State private var scrollPositionDate: Date = Date()
    @State private var rawSelectedDate: Date? = nil

    private let cal = Calendar.current
    private let visibleDomain: TimeInterval = 86400

    private var visiblePoints: [BatteryChartDataPoint] {
        let visibleEnd = Date(timeInterval: visibleDomain, since: scrollPositionDate)
        return points.filter { $0.date >= scrollPositionDate && $0.date <= visibleEnd }
    }
    private var earliestDate: Date {
        points.map(\.date).min() ?? Date()
    }
    private var latestDate: Date {
        points.map(\.date).max() ?? Date()
    }
    private var visibleFirst: Int? {
        visiblePoints.first.map { Int($0.value) }
    }
    private var visibleLast: Int? {
        visiblePoints.last.map { Int($0.value) }
    }
    private var selectedPoint: BatteryChartDataPoint? {
        guard let rawSelectedDate else { return nil }
        return points.min(by: {
            abs($0.date.timeIntervalSince(rawSelectedDate)) < abs($1.date.timeIntervalSince(rawSelectedDate))
        })
    }

    func batteryPoints() -> [BatteryChartDataPoint] {
        let raw = ChartManager.shared.batteryPoints().map {
            BatteryChartDataPoint(date: $0.timestamp ?? Date(), value: $0.value)
        }
        // Keep one point per hour (the last one in each bucket)
        let grouped = Dictionary(grouping: raw) { point -> Date in
            Calendar.current.dateInterval(of: .hour, for: point.date)!.start
        }
        return grouped.map { bucket, samples -> BatteryChartDataPoint in
            let last = samples.max(by: { $0.date < $1.date })!
            return BatteryChartDataPoint(date: bucket.addingTimeInterval(1800), value: last.value)
        }.sorted { $0.date < $1.date }
    }


    func chart() -> some View {
        let xMin = cal.startOfDay(for: earliestDate)
        let xMax = cal.startOfDay(for: latestDate) + visibleDomain

        var chart: some View {
            Chart {
                if let selectedPoint {
                    RuleMark(x: .value("Selected", selectedPoint.date))
                        .foregroundStyle(Color.gray)
                }
                ForEach(points) { point in
                    BarMark(
                        x: .value("Time", point.date),
                        y: .value("Percent", point.value)
                    )
                    .foregroundStyle(point.value.batteryColor)
                    .opacity(selectedPoint == nil || selectedPoint?.id == point.id ? 1 : 0.5)
                }
            }
            .frame(minHeight: 280)
            .padding(.horizontal, 8)
            .chartYScale(domain: 0...100)
            .chartXScale(domain: xMin...xMax)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                    AxisTick(centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }

        return Group {
            if #available(iOS 17, *) {
                chart
                    .chartScrollableAxes(.horizontal)
                    .chartXVisibleDomain(length: visibleDomain)
                    .chartScrollPosition(x: $scrollPositionDate)
                    .chartScrollTargetBehavior(
                        .valueAligned(
                            matching: DateComponents(timeZone: .current, minute: 0, second: 0),
                            majorAlignment: .matching(DateComponents(timeZone: .current, hour: 0))
                        )
                    )
                    .chartXSelection(value: $rawSelectedDate)
            } else {
                chart
            }
        }
    }

    func scrollButton(_ dir: Int, disabled: Bool) -> some View {
        Button {
            scrollPositionDate = cal.date(byAdding: .day, value: dir, to: scrollPositionDate)!
        } label: {
            Image(systemName: dir == 1 ? "chevron.right" : "chevron.left")
                .padding(12)
                .foregroundStyle(Color.primary)
                .fontWeight(.medium)
                .background(Material.regular)
                .clipShape(Circle())
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    var body: some View {
        Group {
            if points.count <= 1 {
                EmptyChartView(.battery)
            } else {
                Section {
                    chart()
                } header: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(selectedPoint != nil ? "Value" : "Range")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Group {
                                if let selectedPoint {
                                    Text(selectedPoint.value / 100, format: .percent.precision(.fractionLength(0)))
                                        .animation(.default, value: selectedPoint.value)
                                } else if let visibleFirst, let visibleLast, visibleFirst == visibleLast {
                                    Text(Double(visibleFirst) / 100, format: .percent.precision(.fractionLength(0)))
                                        .animation(.default, value: visibleFirst)
                                } else if let visibleFirst, let visibleLast {
                                    (Text(Double(visibleFirst) / 100, format: .percent.precision(.fractionLength(0)))
                                    + Text("–")
                                    + Text(Double(visibleLast) / 100, format: .percent.precision(.fractionLength(0))))
                                        .animation(.default, value: visibleFirst)
                                        .animation(.default, value: visibleLast)
                                } else {
                                    Text("--")
                                }
                            }
                            .font(.system(.title, design: .rounded))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                            Group {
                                if let selectedPoint {
                                    Text(selectedPoint.date.addingTimeInterval(-1800).formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                } else {
                                    let rounded = Date(timeIntervalSinceReferenceDate: (scrollPositionDate.timeIntervalSinceReferenceDate / 3600).rounded() * 3600)
                                    let isFullDay = cal.component(.hour, from: rounded) == 0
                                    let end = Date(timeInterval: visibleDomain, since: rounded)
                                    Text(isFullDay
                                         ? rounded.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                                         : "\(rounded.formatted(.dateTime.month(.abbreviated).day())), \(rounded.formatted(.dateTime.hour().minute())) – \(end.formatted(.dateTime.month(.abbreviated).day())), \(end.formatted(.dateTime.hour().minute()))")
                                }
                            }
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        }
                        .fontWeight(.semibold)
                        if #unavailable(iOS 17) {
                            Spacer()
                            scrollButton(-1, disabled: cal.startOfDay(for: scrollPositionDate) <= cal.startOfDay(for: earliestDate))
                            scrollButton(1, disabled: cal.startOfDay(for: scrollPositionDate) >= cal.startOfDay(for: latestDate))
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listRowBackground(Color.clear)
        .onAppear {
            points = batteryPoints()
            scrollPositionDate = cal.startOfDay(for: latestDate)
        }
        .onChange(of: selectedPoint?.date) { newValue in
            guard newValue != nil else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
