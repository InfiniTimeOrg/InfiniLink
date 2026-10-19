//
//  StoredDataView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct StoredDataView: View {
    @AppStorage("dataRetentionMonths") private var months = 0
    
    @State private var pendingMonths: Int?
    @State private var unpairedCount = 0
    @State private var showUnpairedConfirmation = false
    
    private let retention = DataRetention.shared
    
    private func label(_ months: Int) -> String {
        switch months {
        case 0:
            return NSLocalizedString("Forever", comment: "")
        case 12:
            return NSLocalizedString("1 Year", comment: "")
        case let months where months % 12 == 0:
            return String(format: NSLocalizedString("%d Years", comment: ""), months / 12)
        default:
            return String(format: NSLocalizedString("%d Months", comment: ""), months)
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker("Keep Data", selection: Binding(
                    get: { months },
                    set: { newValue in
                        if newValue != 0 && (months == 0 || newValue < months) {
                            pendingMonths = newValue
                        } else {
                            months = newValue
                        }
                    }
                )) {
                    ForEach(DataRetention.monthOptions, id: \.self) { option in
                        Text(label(option)).tag(option)
                    }
                }
            } footer: {
                Text("Heart rate, steps, battery, motion, sleep, and disconnect locations older than this are deleted. Exercises are always kept.")
            }
            if unpairedCount > 0 {
                Section {
                    Button("Delete Data from Unpaired Watches", role: .destructive) {
                        showUnpairedConfirmation = true
                    }
                } footer: {
                    Text(String(format: NSLocalizedString("%d records are from watches that are no longer paired. They come back if you pair the same watch again on this iPhone.", comment: ""), unpairedCount))
                }
            }
        }
        .navigationTitle("Stored Data")
        .onAppear {
            unpairedCount = retention.unpairedRecordCount()
        }
        .confirmationDialog("Delete Old Data", isPresented: Binding(
            get: { pendingMonths != nil },
            set: { if !$0 { pendingMonths = nil } }
        )) {
            Button("Delete Older Data", role: .destructive) {
                if let pendingMonths {
                    months = pendingMonths
                    retention.deleteOldData()
                }
            }
        } message: {
            Text("Data older than \(label(pendingMonths ?? 0).lowercased()) will be deleted from InfiniLink. Data saved to Apple Health isn't affected.")
        }
        .confirmationDialog("Delete Unpaired Watch Data", isPresented: $showUnpairedConfirmation) {
            Button("Delete Data", role: .destructive) {
                retention.deleteUnpairedData {
                    unpairedCount = retention.unpairedRecordCount()
                }
            }
        } message: {
            Text("All data from watches that are no longer paired, including their exercises, will be deleted from InfiniLink. Data saved to Apple Health isn't affected.")
        }
    }
}

#Preview {
    NavigationStack {
        StoredDataView()
    }
}
