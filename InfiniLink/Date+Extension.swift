//
//  Date+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/10/24.
//

import Foundation

extension Date {
    func comparable() -> String {
        return self.formatted(.dateTime.dayOfYear())
    }
    
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
    
    static var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components)!
    }
    
    static var endOfMonth: Date {
        let calendar = Calendar.current
        let startOfMonth = Date.startOfMonth
        let components = DateComponents(month: 1, day: -1)
        return calendar.date(byAdding: components, to: startOfMonth)!
    }
    
    static func monthFromInt(_ month: Int) -> String {
        let monthSymbols = Calendar.current.monthSymbols
        return monthSymbols[month]
    }
    
    static func monthAbbreviationFromInt(_ month: Int) -> String {
        let monthSymbols = Calendar.current.shortMonthSymbols
        return monthSymbols[month]
    }
    
    static func getDateFrom(month: Int) -> Date {
        var components = DateComponents()
        components.month = month
        
        let calendar = Calendar.current
        components.year = calendar.component(.year, from: Date())
        components.day = 1
        
        return calendar.date(from: components) ?? Date()
    }
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components)!
    }
}

func date(year: Int, month: Int, day: Int = 1, hour: Int = 0, minutes: Int = 0, seconds: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minutes, second: seconds)) ?? Date()
}
