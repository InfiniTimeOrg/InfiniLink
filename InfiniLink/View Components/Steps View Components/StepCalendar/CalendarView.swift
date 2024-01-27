//
//  CalendarView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/27/21.
//
//


import SwiftUI

struct CalendarView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    
    @State var interval: DateInterval = DateInterval()
    let showHeaders: Bool
    let content: (Date) -> DateView
    @State var selectedDate = Date()
    
    init(
        showHeaders: Bool = true,
        @ViewBuilder content: @escaping (Date) -> DateView
    ) {
        self.showHeaders = showHeaders
        self.content = content
    }
    
    var body: some View {
        let weekdays = calendar.veryShortWeekdaySymbols
        LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
            ForEach(months, id: \.self) { month in
                Section(header: header(for: month)) {
                    ForEach(0..<7) {
                        Text(weekdays[$0])
                    }
                    ForEach(days(for: month), id: \.self) { date in
                        if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                            content(date).id(date)
                        } else {
                            content(date).hidden()
                            // .foregroundColor(Color.gray)
                        }
                    }
                }
            }
        }
    }
    
    
    private func setInterval(month: Int) {
        if month == 0 {
            interval = calendar.dateInterval(of: .month, for: Date())!
        } else {
            selectedDate = Calendar.current.date(byAdding: .month, value: month, to: selectedDate)!
            interval = calendar.dateInterval(of: .month, for: selectedDate)!
        }
    }
    
    private var months: [Date] {
        calendar.generateDates(
            inside: interval,
            matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
        )
    }
    
    private func header(for date: Date) -> some View {
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let formatter = DateFormatter()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        
        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(formatter.monthSymbols[month - 1]) // Use monthSymbols to get the month name
                    .font(.title2.weight(.semibold))
                if let formattedYear = numberFormatter.string(from: NSNumber(value: year)) {
                    Text(formattedYear)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: {
                self.setInterval(month: -1)
            }) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .modifier(BlueButtonModifer())
            }
            Button(action: {
                self.setInterval(month: 0)
            }) {
                Text("Today")
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            Button(action: {
                self.setInterval(month: 1)
            }) {
                Image(systemName: "chevron.right")
                    .imageScale(.large)
                    .modifier(BlueButtonModifer())
            }
        }
    }
    
    private func days(for month: Date) -> [Date] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end)
        else { return [] }
        return calendar.generateDates(
            inside: DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end),
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }
}

struct BlueButtonModifer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Circle())
            .animation(.none)
    }
}

#Preview {
    CalendarView { date in
        
    }
}

