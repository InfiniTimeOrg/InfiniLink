//
//  RemindersManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/14/24.
//

import EventKit
import SwiftUI

class RemindersManager: ObservableObject {
    static let shared = RemindersManager()
    
    @Published var reminders = [EKReminder]()
    @Published var events = [EKEvent]()
    @Published var notifiedItems = [String: Date]()
    @Published var areEventsAuthorized = false
    @Published var areRemindersAuthorized = false
    
    var eventStore = EKEventStore()
    var timer: Timer?
    
    @AppStorage("enableReminders") var enableReminders = true
    @AppStorage("enableCalendarNotifications") var enableCalendarNotifications = true
    
    func checkForDueItems() {
        let currentDate = Date()
        
        for reminder in reminders {
            checkDueReminder(reminder, currentDate: currentDate)
        }
        for event in events {
            checkDueEvent(event, currentDate: currentDate)
        }
    }
    
    private func checkDueReminder(_ reminder: EKReminder, currentDate: Date) {
        let reminderId = reminder.calendarItemIdentifier
        guard let dueDate = reminder.dueDateComponents?.date, !reminder.isCompleted else { return }
        
        if let lastNotifiedDate = notifiedItems[reminderId], lastNotifiedDate != dueDate {
            notifiedItems.removeValue(forKey: reminderId)
        }
        
        if !notifiedItems.keys.contains(reminderId), Calendar.current.isDate(dueDate, equalTo: currentDate, toGranularity: .minute) {
            NotificationManager.shared.sendReminderDueNotification(reminder)
            notifiedItems[reminderId] = dueDate
        }
    }
    
    private func checkDueEvent(_ event: EKEvent, currentDate: Date) {
        let eventId = event.calendarItemIdentifier
        guard !event.isAllDay, let eventStartDate = event.startDate, eventStartDate >= currentDate else { return }
        
        if let lastNotifiedDate = notifiedItems[eventId], lastNotifiedDate != eventStartDate {
            notifiedItems.removeValue(forKey: eventId)
        }
        
        if !notifiedItems.keys.contains(eventId), Calendar.current.isDate(eventStartDate, equalTo: currentDate, toGranularity: .minute) {
            NotificationManager.shared.sendEventDueNotification(event)
            notifiedItems[eventId] = eventStartDate
        }
    }
    
    func fetchAllItems() {
        if enableReminders {
            fetchReminders()
        }
        if enableCalendarNotifications {
            fetchEvents()
        }
    }
    
    private func fetchReminders() {
        eventStore.fetchReminders(matching: eventStore.predicateForReminders(in: nil)) { reminders in
            guard let reminders = reminders else { return }
            DispatchQueue.main.async {
                self.reminders = reminders
            }
        }
    }
    
    private func fetchEvents() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        DispatchQueue.main.async {
            self.events = self.eventStore.events(matching: predicate)
        }
    }
    
    func requestReminderAccess() {
        eventStore.requestAccess(to: .reminder) { granted, error in
            if let error = error {
                log("Unknown error while requesting reminder access: \(error.localizedDescription)", caller: "RemindersManager")
                print(error.localizedDescription)
            } else if granted {
                DispatchQueue.main.async {
                    self.areRemindersAuthorized = true
                    self.fetchAllItems()
                }
            }
        }
    }
    
    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            if let error = error {
                log("Unknown error while requesting calendar access: \(error.localizedDescription)", caller: "RemindersManager")
                print(error.localizedDescription)
            } else if granted {
                DispatchQueue.main.async {
                    self.areEventsAuthorized = true
                    self.fetchAllItems()
                }
            }
        }
    }
    
    func requestAccess() {
        requestReminderAccess()
        requestCalendarAccess()
    }
}
