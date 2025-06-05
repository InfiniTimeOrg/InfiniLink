//
//  StepMonthlyChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/4/25.
//

import SwiftUI
import BottomSheet

struct StepCalendarView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showPopover = false
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
                let stepPoints = chartManager.stepPoints(predicate: chartManager.allTimePredicate)
                let rows = fetchDates().chunked(into: weekdays.count)
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 14) {
                        ForEach(row, id: \.id) { day in
                            CalendarDayView(day, points: stepPoints)
                                .onTapGesture {
                                    selectedDate = day.date
                                    showPopover = true
                                }
                                .frame(maxWidth: .infinity)
                        }
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
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .padding(12)
                            .background(background)
                            .clipShape(Circle())
                    }
                    .disabled(fetchSelectedMonth(selectedMonth + 1) > Date())
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
        .bottomSheet(isPresented: $showPopover, detents: [.medium()]) {
            CalendarDayDetailView(selectedDay: $selectedDate)
        }
    }
    
    func fetchDates() -> [CalendarDay] {
        let calendar = Calendar.current
        let currentMonth = fetchSelectedMonth()
        
        var dates = currentMonth.datesOfMonth().map {
            CalendarDay(day: calendar.component(.day, from: $0), date: $0)
        }
        
        // Calculate leading empty days
        let firstWeekday = calendar.component(.weekday, from: dates.first?.date ?? Date()) - calendar.firstWeekday
        let leadingEmpty = (firstWeekday + 7) % 7 // Ensure non-negative
        
        for _ in 0..<leadingEmpty {
            dates.insert(CalendarDay(day: -1, date: Date()), at: 0)
        }
        
        // Calculate trailing empty days
        let remainder = dates.count % 7
        let trailingEmpty = (remainder == 0 ? 0 : (7 - remainder))
        
        for _ in 0..<trailingEmpty {
            dates.append(CalendarDay(day: -1, date: Date()))
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

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    List {
        StepCalendarView()
    }
}
