//
//  Date+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/10/24.
//

import Foundation

extension Date {
    func datesOfMonth() -> [Date] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: self)
        let currentYear = calendar.component(.year, from: self)
        
        var startDateComponents = DateComponents()
        startDateComponents.month = currentMonth
        startDateComponents.year = currentYear
        startDateComponents.day = 1
        let startDate = calendar.date(from: startDateComponents)!
        
        var endDateComponents = DateComponents()
        endDateComponents.month = 1
        endDateComponents.day = -1
        let endDate = calendar.date(byAdding: endDateComponents, to: startDate)!
        
        var dates = [Date]()
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
}

extension Date.FormatStyle.Symbol.Hour {
    // Forcing 24-hour time on a 12-hour locale drops the leading zero
    static var localized: Self {
        let uses24Hour = !(DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "").contains("a")
        return uses24Hour ? .twoDigits(amPM: .omitted) : .defaultDigits(amPM: .abbreviated)
    }
}
