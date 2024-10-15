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
    @Published var isAuthorized = false
    
    var eventStore = EKEventStore()
    
    var timer: Timer?
    
    @AppStorage("enableReminders") var enableReminders = true
    
    init() {
        startCheckingForDueReminders()
    }
    
    func startCheckingForDueReminders() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.checkForDueReminders()
        }
    }
    
    func checkForDueReminders() {
        let currentTime = Date()
        
        for reminder in reminders {
            if let dueDate = reminder.dueDateComponents?.date, dueDate == currentTime, !reminder.isCompleted {
                NotificationManager.shared.sendReminderDueNotification(reminder)
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
    
    func completeReminder(_ reminder: EKReminder) {
        reminder.isCompleted = true
        
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print(error.localizedDescription)
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
