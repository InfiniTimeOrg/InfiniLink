//
//  FileSystemDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import SwiftUI

struct FileSystemDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var settings: Settings? = nil
    
    func row(key: String, value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let settings = settings {
                    List {
                        row(key: NSLocalizedString("Display Timeout", comment: ""), value: "\(settings.screenTimeOut / 1000) Seconds")
                        row(key: NSLocalizedString("Brightness Level", comment: ""), value: {
                            switch settings.brightLevel {
                            case .Low:
                                return "Low"
                            case .Mid:
                                return "Mid"
                            case .High:
                                return "High"
                            }
                        }())
                        row(key: NSLocalizedString("Time Format", comment: ""), value: {
                            switch settings.clockType {
                            case .H12:
                                return "12 Hour"
                            case .H24:
                                return "24 Hour"
                            }
                        }())
                        row(key: NSLocalizedString("Steps Goal", comment: ""), value: String(settings.stepsGoal))
                        row(key: NSLocalizedString("Weather Format", comment: ""), value: {
                            switch settings.weatherFormat {
                            case .Imperial:
                                return "Imperial"
                            case .Metric:
                                return "Metric"
                            }
                        }())
                        row(key: NSLocalizedString("Hourly Chimes", comment: ""), value: {
                            switch settings.chimesOption {
                            case .None:
                                return "None"
                            case .Hours:
                                return "Hour"
                            case .HalfHours:
                                return "Half Hour"
                            }
                        }())
                    }
                } else {
                    Text("Only settings files are currently supported.")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .frame(maxHeight: .infinity)
                }
            }
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                // TODO: read other files
                BLEFSHandler.shared.readSettings { settings in
                    self.settings = settings
                    
                    // While we're already loading the settings, make sure we keep the vars updated
                    BLEManager.shared.setSettings(from: settings)
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    FileSystemDetailView()
}
