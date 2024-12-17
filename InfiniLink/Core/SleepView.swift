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
                        if let seconds = sleepController.totalSleepSeconds {
                            let minutes = seconds / 60
                            
                            if minutes < 60 {
                                return "\(minutes)min\(minutes > 1 ? "s" : "")"
                            } else {
                                let hours = minutes / 60
                                return "\(hours)hr\(hours > 1 ? "s" :"") \(minutes)min\(minutes > 1 ? "s" : "")"
                            }
                        }
                        return "0hrs"
                    }(), subtitle: {
                        if let sleep = sleepController.sleep {
                            return "\(sleep.startDate.formatted()) - \(sleep.endDate.formatted())"
                        }
                        return nil
                    }(), icon: "bed.double.fill", accent: .purple), width: geo.size.width) {
                        Button {
                            // We can't current change the tracking state over BLE
                        } label: {
                            Text("Stop Tracking")
                                .padding(14)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
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
