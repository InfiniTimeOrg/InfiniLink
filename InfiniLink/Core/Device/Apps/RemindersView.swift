//
//  RemindersView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI
import EventKit

struct RemindersView: View {
    @ObservedObject var remindersManager = RemindersManager.shared
    
    @State private var authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    
    var body: some View {
        Group {
            switch authorizationStatus {
            case .authorized, .fullAccess:
                authorized
            case .denied, .notDetermined, .restricted, .writeOnly:
                unauthorized
            @unknown default:
                unauthorized
            }
        }
        .onChange(of: remindersManager.isAuthorized) { allowed in
            if allowed {
                remindersManager.requestReminderAccess()
            }
        }
    }
    
    var authorized: some View {
        List {
            ForEach(remindersManager.reminders.filter({ $0.isCompleted == false }), id: \.hashValue) { reminder in
                Button {
                    remindersManager.completeReminder(reminder)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.title)
                            if let dueDate = reminder.dueDateComponents, let date = Calendar.current.date(from: dueDate) {
                                Text("Notifying on " + date.formatted())
                                    .foregroundStyle(.gray)
                            }
                        }
                        Spacer()
                        Image(systemName: "circle")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .navigationTitle("Reminders")
    }
    
    var unauthorized: some View {
        ActionView(action: Action(title: "We need access to your Reminders.", subtitle: "To receive reminders on your watch, you'll need to give InfiniLink full access to them.", icon: "checklist", action: {
            if authorizationStatus == .notDetermined {
                remindersManager.requestReminderAccess()
            } else {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }, actionLabel: authorizationStatus == .notDetermined ? "Allow Access..." : "Open Settings...", accent: .blue))
    }
}

#Preview {
    RemindersView()
}
