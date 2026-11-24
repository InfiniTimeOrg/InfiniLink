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

private struct OutlinedBolt: View { // Can't add a stroke to an sf symbol
    @Environment(\.colorScheme) private var colorScheme

    private let borderWidth: CGFloat = 2.25
    private let steps = 16 // Enough copies so it's smooth

    var body: some View {
        let bolt = Image(systemName: "bolt.fill").font(.system(size: 12, weight: .bold))
        ZStack {
            ForEach(0..<steps, id: \.self) { index in
                let angle = Double(index) / Double(steps) * 2 * .pi
                bolt.offset(x: cos(angle) * borderWidth, y: sin(angle) * borderWidth)
            }
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            bolt
                .foregroundStyle(Color.green)
        }
        .padding(borderWidth)
        .drawingGroup()
    }
}

struct BatteryChartView: View {
    @ObservedObject var bleManager = BLEManager.shared

    @State private var points = [BatteryChartDataPoint]()
    @State private var chargingHours = [Date]()
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
    private var chargingRuns: [DateInterval] {
        var runs = [DateInterval]()
        for hour in chargingHours {
            if let last = runs.last, last.end == hour {
                runs[runs.count - 1].end = hour.addingTimeInterval(3600)
            } else {
                runs.append(DateInterval(start: hour, duration: 3600))
            }
        }
        return runs
    }
    private func boltPlacement(for run: DateInterval) -> (date: Date, fits: Bool) {
        let visible = run.intersection(with: DateInterval(start: scrollPositionDate, duration: visibleDomain)) ?? run
        return (visible.start.addingTimeInterval(visible.duration / 2), visible.duration >= 5400)
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
        let grouped = Dictionary(grouping: raw) { point -> Date in
            Calendar.current.dateInterval(of: .hour, for: point.date)!.start
        }
        return grouped.map { bucket, samples -> BatteryChartDataPoint in
            let last = samples.max(by: { $0.date < $1.date })!
            return BatteryChartDataPoint(date: bucket.addingTimeInterval(1800), value: last.value)
        }.sorted { $0.date < $1.date }
    }

    func chargingHourStarts() -> [Date] {
        let intervals = BatteryStats.chargerIntervals(from: ChartManager.shared.batteryPoints())
        return Set(intervals.flatMap { interval -> [Date] in
            var hours = [Date]()
            var hour = cal.dateInterval(of: .hour, for: interval.start)!.start
            while hour < interval.end {
                hours.append(hour)
                hour.addTimeInterval(3600)
            }
            return hours
        }).sorted()
    }

    func chart() -> some View {
        let xMin = cal.startOfDay(for: earliestDate)
        let xMax = cal.startOfDay(for: latestDate) + visibleDomain

        var chart: some View {
            Chart {
                ForEach(chargingHours, id: \.self) { hour in
                    RectangleMark(
                        xStart: .value("Start", hour),
                        xEnd: .value("End", hour.addingTimeInterval(3600)),
                        yStart: .value("Bottom", 0),
                        yEnd: .value("Top", 100)
                    )
                    .foregroundStyle(Color.green.opacity(0.15))
                }
                ForEach(chargingRuns, id: \.start) { run in
                    RectangleMark(
                        xStart: .value("Start", run.start),
                        xEnd: .value("End", run.end),
                        yStart: .value("Bottom", -5),
                        yEnd: .value("Top", -3)
                    )
                    .cornerRadius(2.5)
                    .foregroundStyle(Color.green)
                    let bolt = boltPlacement(for: run)
                    PointMark(
                        x: .value("Time", bolt.date),
                        y: .value("Charging", -4)
                    )
                    .symbol {
                        OutlinedBolt()
                            .opacity(bolt.fits ? 1 : 0)
                            .animation(.easeOut(duration: 0.2), value: bolt.fits)
                    }
                }
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
            .chartYScale(domain: -14...100)
            .chartXScale(domain: xMin...xMax)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                    AxisTick(centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: [0, 25, 50, 75, 100]) { value in
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
                                    Text("No Data")
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
            chargingHours = chargingHourStarts()
            scrollPositionDate = cal.startOfDay(for: latestDate)
        }
        .onChange(of: selectedPoint?.date) { newValue in
            guard newValue != nil else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
