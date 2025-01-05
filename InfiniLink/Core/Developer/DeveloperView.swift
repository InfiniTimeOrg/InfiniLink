//
//  DeveloperView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/14/24.
//

import SwiftUI

struct DeveloperView: View {
    let bleWriteManager = BLEWriteManager()
    
    @AppStorage("useExperimentalDFU") var useExperimentalDFU = false
    
    var body: some View {
        List {
            Section {
                NavigationLink("Debug Logs") {
                    DebugLogsView()
                }
            }
            Section {
                Button("Test Weather") {
                    bleWriteManager.writeForecastWeatherData(minimumTemperature: {
                        var mins = [Double]()
                        
                        for _ in 0...4 {
                            mins.append(Double.random(in: -2...50))
                        }
                        
                        return mins
                    }(), maximumTemperature: {
                        var maxs = [Double]()
                        
                        for _ in 0...4 {
                            maxs.append(Double.random(in: -2...50))
                        }
                        
                        return maxs
                    }(), icon: {
                        var icons = [UInt8]()
                        
                        for _ in 0...8 {
                            icons.append(UInt8.random(in: 0...8))
                        }
                        
                        return icons
                    }())
                    bleWriteManager.writeCurrentWeatherData(currentTemperature: Double.random(in: -2...50), minimumTemperature: Double.random(in: -2...50), maximumTemperature: Double.random(in: -2...50), location: "Location", icon: UInt8.random(in: 0...8))
                }
                Button("Test Navigation") {
                    bleWriteManager.writeNavigationUpdate()
                }
            } header: {
                Text("Test Data")
            } footer: {
                Text("Send randomly generated data to the various characteristics on the watch.")
            }
            Section {
                Toggle("Use Experimental DFU", isOn: $useExperimentalDFU)
            }
            Section("Charts") {
                Button(role: .destructive) {
                    StepCountManager.shared.clearCurrentDaySteps()
                } label: {
                    Text("Clear Step Data")
                }
            }
        }
        .navigationTitle("Developer")
    }
}

#Preview {
    DeveloperView()
}
