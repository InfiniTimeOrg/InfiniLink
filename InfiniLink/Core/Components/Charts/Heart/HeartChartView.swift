//
//  HeartChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import SwiftUI
import Charts

struct HeartChartDataPoint: Identifiable {
    var id = UUID()
    let date: Date
    let min: Double
    let max: Double
    let average: Double
    let values: [Double]
}

struct HeartChartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @AppStorage("heartRateChartDataSelection") private var dataSelection = 0
    @AppStorage("minHeartRange") private var minHeartRange = 40
    @AppStorage("maxHeartRange") private var maxHeartRange = 200
    
    @State private var points = [HeartChartDataPoint]()
    @State private var dayOffset: Int = 0
    @State private var displayedDate: Date = Date()
    @State private var displayedMin: Int = 0
    @State private var displayedMax: Int = 0
    @State private var scrollPositionDate: Date = Date()

    var windowStart: Date {
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!)
    }
    var windowEnd: Date {
        Date(timeInterval: 86400, since: windowStart)
    }
    var windowPoints: [HeartChartDataPoint] {
        points.filter { $0.date >= windowStart && $0.date <= windowEnd }
    }
    
    var visiblePoints: [HeartChartDataPoint] {
        let visibleEnd = Date(timeInterval: 86400, since: scrollPositionDate)
        return points.filter { $0.date >= scrollPositionDate && $0.date <= visibleEnd }
    }
    var visibleMin: Int {
        Int(visiblePoints.map({ $0.min }).min() ?? 0)
    }
    var visibleMax: Int {
        Int(visiblePoints.map({ $0.max }).max() ?? 0)
    }
    
    func heartPoints() -> [HeartChartDataPoint] {
        let raw = ChartManager.shared.heartPoints()
        
        let grouped = Dictionary(grouping: raw) { sample -> Date in
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: sample.timestamp ?? Date())
            return Calendar.current.date(from: comps) ?? Date()
        }
        
        return grouped.map { (bucket, samples) in
            let values = samples.map { $0.value }
            return HeartChartDataPoint(
                date: Calendar.current.date(byAdding: .minute, value: 30, to: bucket) ?? bucket,
                min: values.min() ?? 0,
                max: values.max() ?? 0,
                average: {
                    let sorted = values.sorted()
                    let mid = sorted.count / 2
                    return sorted.count % 2 == 0
                        ? (sorted[mid - 1] + sorted[mid]) / 2
                        : sorted[mid]
                }(),
                values: values
            )
        }.sorted { $0.date < $1.date }
    }
    
    var earliestDate: Date {
        points.map({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        points.map({ $0.date }).max() ?? Date()
    }
    
    let heartColor = Color(red: 0.996, green: 0.212, blue: 0.369)
    let darkHeartColor = Color(red: 0.369, green: 0.090, blue: 0.145)
    
    func isSingleReading(_ point: HeartChartDataPoint) -> Bool {
        point.min == point.max
    }
    
    @ChartContentBuilder
    func chartContent(for point: HeartChartDataPoint) -> some ChartContent {
        if isSingleReading(point) {
            PointMark(
                x: .value("Time", point.date),
                y: .value("BPM", point.min)
            )
            .foregroundStyle(heartColor)
            .symbolSize(40)
            .symbol(.circle)
        } else {
            RectangleMark(
                x: .value("Time", point.date),
                yStart: .value("Min", point.min),
                yEnd: .value("Max", point.max),
                width: 7
            )
            .foregroundStyle(darkHeartColor)
            .clipShape(Capsule())
            
            PointMark(
                x: .value("Time", point.date),
                y: .value("BPM", point.average)
            )
            .foregroundStyle(heartColor)
            .symbolSize(CGSize(width: 7, height: 7))
            .symbol(.circle)
        }
    }
    
    func updateDisplayed() {
        displayedDate = windowStart
        displayedMin = Int(windowPoints.map({ $0.min }).min() ?? 0)
        displayedMax = Int(windowPoints.map({ $0.max }).max() ?? 0)
    }
    
    func chartPage(for offset: Int) -> some View {
        let start = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: offset, to: Date())!)
        let end = Date(timeInterval: 86400, since: start)
        let pagePoints = points.filter { $0.date >= start && $0.date <= end }
        let pageMin = Int(pagePoints.map({ $0.min }).min() ?? 0)
        let pageMax = Int(pagePoints.map({ $0.max }).max() ?? 0)

        return Chart {
            ForEach(pagePoints) { point in
                chartContent(for: point)
            }
        }
        .frame(height: 280)
        .padding(.horizontal, 8)
        .chartYScale(domain: (pageMin - 20)...(pageMax + 20))
        .chartXScale(domain: start...end)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    
    var pagedChart: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dayOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(Calendar.current.isDate(windowStart, inSameDayAs: earliestDate))
                
                Spacer()
                
                Button {
                    dayOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(dayOffset >= 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .padding(.bottom, 8)
            
            chartPage(for: dayOffset)
        }
    }
    
    @available(iOS 17, *)
    var scrollableChart: some View {
        Chart {
            ForEach(points) { point in
                chartContent(for: point)
            }
        }
        .frame(height: 280)
        .padding(.horizontal, 8)
        .chartYScale(domain: (displayedMin - 20)...(displayedMax + 20))
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 86400)
        .chartXScale(domain: (earliestDate - 1800)...(latestDate + 1800))
        .chartScrollPosition(x: $scrollPositionDate)
        .chartScrollTargetBehavior(.valueAligned(unit: 3600))
    }
    
    var body: some View {
        Group {
            Group {
                if points.count <= 1 {
                    EmptyChartView(.heart)
                } else {
                    Section {
                        VStack(spacing: 0) {
                            if #available(iOS 17, *) {
                                scrollableChart
                            } else {
                                pagedChart
                            }
                        }
                        .buttonStyle(.plain)
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Range")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(displayedMax == 0 || displayedMin == 0 ? "0 " : "\(displayedMin)–\(displayedMax) ")
                                .font(.system(.title, design: .rounded))
                                .foregroundColor(.primary)
                            + Text("BPM")
                            Text(displayedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .fontWeight(.semibold)
                    }
                    .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .listRowBackground(Color.clear)
            if points.count >= 3 {
                Section {
                    Text("Today your heart rate reached a high of \(displayedMax), and dropped to a low of \(displayedMin) BPM.")
                }
            }
        }
        .onAppear {
            points = heartPoints()
            scrollPositionDate = windowStart
            updateDisplayed()
        }
        .onChange(of: dayOffset) { _ in
            updateDisplayed()
        }
        .onChange(of: scrollPositionDate) { newValue in
            displayedDate = newValue
        }
        .onChange(of: scrollPositionDate) { newValue in
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if scrollPositionDate == newValue {
                    let clamped = min(max(newValue, Calendar.current.startOfDay(for: earliestDate)), Calendar.current.startOfDay(for: latestDate))
                    if clamped != newValue {
                        scrollPositionDate = clamped
                    }
                    displayedMin = visibleMin
                    displayedMax = visibleMax
                }
            }
        }
        .onChange(of: bleManager.heartRate) { _ in
            points = heartPoints()
            updateDisplayed()
        }
    }
}
