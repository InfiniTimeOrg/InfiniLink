//
//  SleepView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct SleepView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var sleepController = SleepController.shared
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: {
                        if let minutes = sleepController.totalSleepMinutes {
                            if minutes < 60 {
                                return "\(minutes) min\(minutes > 1 ? "s" : "")"
                            } else {
                                let hours = minutes / 60
                                let remainingMinutes = minutes % 60
                                return "\(hours)hr\(hours > 1 ? "s" : "") \(remainingMinutes)min\(remainingMinutes > 1 ? "s" : "")"
                            }
                        }
                        return "0 hrs"
                    }(), subtitle: {
                        if let sleep = sleepController.sleep {
                            return "\(sleep.startDate.formatted()) - \(sleep.endDate.formatted())"
                        }
                        return nil
                    }(), icon: "bed.double.fill", accent: .indigo), width: geo.size.width) {
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                
            }
        }
        .navigationTitle("Sleep")
    }
}

#Preview {
    SleepView()
}
