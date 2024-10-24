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
    @Published var notifiedReminders = [String: Date]()
    @Published var isAuthorized = false
    
    var eventStore = EKEventStore()
    
    var timer: Timer?
    
    @AppStorage("enableReminders") var enableReminders = true
    
    func checkForDueReminders() {
        for reminder in reminders {
            let reminderId = reminder.calendarItemIdentifier
            guard let dueDate = reminder.dueDateComponents?.date, !reminder.isCompleted else {
                continue
            }
            
            if let lastNotifiedDate = notifiedReminders[reminderId] {
                if lastNotifiedDate != dueDate {
                    // The user has changed the due date, so notify again
                    notifiedReminders.removeValue(forKey: reminderId)
                }
            }
            
            if !notifiedReminders.keys.contains(reminderId) {
                let calendar = Calendar.current
                
                let dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
                let currentDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
                
                if dueDateComponents == currentDateComponents {
                    NotificationManager.shared.sendReminderDueNotification(reminder)
                    
                    notifiedReminders[reminderId] = dueDate
                }
            }
        }
    }
    
    func fetchAllReminders() {
        if enableReminders {
            eventStore.fetchReminders(matching: eventStore.predicateForReminders(in: nil)) { reminders in
                guard let reminders = reminders else { return }
                
                DispatchQueue.main.async {
                    self.reminders = reminders
                }
            }
        }
    }
    
    func requestReminderAccess() {
        eventStore.requestAccess(to: .reminder) { granted, error in
            if let error = error {
                print(error.localizedDescription)
            } else if granted {
                DispatchQueue.main.async {
                    self.isAuthorized = true
                    self.fetchAllReminders()
                }
            }
        }
    }
}
