//
//  StepMonthlyChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/4/25.
//

import SwiftUI

struct StepCalendarView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedMonth = 0
    @State private var selectedDate = Date()
    
    var weekdays: [String] {
        let calendar = Calendar.current
        return calendar.veryShortStandaloneWeekdaySymbols
    }
    var background: AnyShapeStyle {
        return colorScheme == .dark ? AnyShapeStyle(Material.regular) : AnyShapeStyle(Color(.systemBackground))
    }
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                HStack {
                    ForEach(Array(weekdays.enumerated()), id: \.0) { index, day in
                        Text(day)
                            .font(.system(size: 14).weight(.bold))
                            .foregroundStyle(Color.primary.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }
                // FIXME: poor performance
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: weekdays.count), spacing: 14) {
                    ForEach(fetchDates(), id: \.id) { value in
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.8), style: value.day == -1 ? StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7]) : StrokeStyle(lineWidth: 0))
                                .background(value.day == -1 ? AnyShapeStyle(Color.clear) : background)
                                .clipShape(Circle())
                            let label = Text("\(value.day)")
                                .font(.system(size: 16).weight(.medium))
                                .opacity(value.day == -1 ? 0 : 1)
                            if deviceManager.settings.stepsGoal > 0 && value.day != -1 {
                                let progress = min(Double(chartManager.stepPoints().first(where: { Calendar.current.isDate(value.date, equalTo: $0.timestamp!, toGranularity: .day)})?.steps ?? 0) / Double(deviceManager.settings.stepsGoal), 1)
                                PieSlice(progress: progress)
                                    .fill(Color.blue.opacity(0.8))
                                label
                                    .foregroundStyle(progress > 0.5 ? Color.white : Color.primary)
                            } else {
                                label
                            }
                        }
                        .frame(minWidth: 42, maxWidth: 55, minHeight: 42, maxHeight: 55)
                    }
                }
            }
        } header: {
            VStack(alignment: .leading, spacing: 7) {
                Text("Monthly Overview")
                HStack(spacing: 12) {
                    Button {
                        selectedMonth -= 1
                        selectedDate = fetchSelectedMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .padding(10)
                            .background(background)
                            .clipShape(Circle())
                    }
                    Text("\(selectedDate.formatted(.dateTime.month(.wide).year()))")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                    Button {
                        selectedMonth += 1
                        selectedDate = fetchSelectedMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .padding(10)
                            .background(background)
                            .clipShape(Circle())
                    }
                    .disabled(fetchSelectedMonth(selectedMonth + 1) > Date())
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
    }
    
    func fetchDates() -> [CalendarDay] {
        let calendar = Calendar.current
        let currentMonth = fetchSelectedMonth()
        
        var dates = currentMonth.datesOfMonth().map({ CalendarDay(day: calendar.component(.day, from: $0), date: $0) })
        let firstDayOfWeek = calendar.component(.weekday, from: dates.first?.date ?? Date()) - 1
        
        for _ in 0..<firstDayOfWeek {
            dates.insert(CalendarDay(day: -1, date: Date()), at: 0)
        }
        
        return dates
    }
    
    func fetchSelectedMonth(_ month: Int? = nil) -> Date {
        let selectedMonth = month ?? selectedMonth
        let calendar = Calendar.current
        let month = calendar.date(byAdding: .month, value: selectedMonth, to: Date())!
        
        return month
    }
}

struct PieSlice: Shape {
    var progress: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle(degrees: -90) // Start from the top
        let endAngle = Angle(degrees: -90 + (progress * 360))
        
        path.move(to: center)
        path.addLine(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    List {
        StepCalendarView()
    }
}
