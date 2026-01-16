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
    
    @State private var showPopover = false
    @State private var selectedMonth = 0
    @State private var selectedDate = Date()
    @State private var selectedPoint: StepCounts?
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var stepPoints = [StepCounts]()
    @State private var fetchedDates = [CalendarDay]()
    
    var weekdays: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
    var background: AnyShapeStyle {
        return colorScheme == .dark ? AnyShapeStyle(Material.regular) : AnyShapeStyle(Color(.systemBackground))
    }
    
    private func showPointPopover(_ day: CalendarDay, _ point: StepCounts?) {
        guard day.day != -1 else { return } // Don't show anything for the next/previous month's days
        
        selectedPoint = point
        selectedDate = day.date
        selectedDetent = .medium
        showPopover = true
    }
    
    var body: some View {
        Section {
            VStack(spacing: 10) {
                HStack {
                    ForEach(Array(weekdays.enumerated()), id: \.0) { index, day in
                        Text(day)
                            .font(.system(size: 14).weight(.bold))
                            .foregroundStyle(Color.primary.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }
                VStack {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: weekdays.count), spacing: 14) {
                        ForEach(fetchedDates, id: \.id) { day in
                            let point = stepPoints.first(where: { Calendar.current.isDate(day.date, equalTo: $0.timestamp!, toGranularity: .day)})
                            CalendarDayView(day, point: point)
                                .onTapGesture(perform: { showPointPopover(day, point) })
                        }
                    }
                }
                .sheet(isPresented: $showPopover) {
                    CalendarDayDetailView($selectedPoint, selectedDetent: $selectedDetent, selectedDate: selectedDate)
                        .presentationDetents([.medium], selection: $selectedDetent)
                }
            }
            .padding(.bottom)
        } header: {
            VStack(alignment: .leading, spacing: 7) {
                Text("Monthly Overview")
                HStack(spacing: 12) {
                    Button {
                        setMonth(up: false)
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
                        setMonth(up: true)
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
        .onAppear {
            getStepPoints()
        }
    }
    
    func getStepPoints() {
        fetchedDates = fetchDates()
        stepPoints = chartManager.stepPoints(predicate: chartManager.monthPredicate(offset: selectedMonth))
    }
    
    func setMonth(up: Bool) {
        selectedMonth += (up ? 1 : -1)
        selectedDate = fetchSelectedMonth()
        getStepPoints()
    }
    
    func fetchDates() -> [CalendarDay] {
        let calendar = Calendar.current
        let currentMonth = fetchSelectedMonth()
        
        var dates = currentMonth.datesOfMonth().map {
            CalendarDay(day: calendar.component(.day, from: $0), date: $0)
        }
        
        // Calculate leading empty days
        let firstWeekday = calendar.component(.weekday, from: dates.first?.date ?? Date()) - calendar.firstWeekday
        let leadingEmpty = calendar.ordinality(of: .weekday,
                                               in: .weekOfMonth,
                                               for: dates.first!.date)! - 1
        
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
