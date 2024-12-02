//
//  HeartSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct HeartSettingsView: View {
    @AppStorage("backgroundHRMMeasurements") var backgroundHRMMeasurements = false
    @AppStorage("filterHeartRateData") var filterHeartRateData = true
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    
    func generateCSV(from points: [HeartDataPoint]) -> String {
        var csvString = "Timestamp,Value\n"
        
        for point in points {
            csvString += "\(escapeField(point.timestamp?.formatted() ?? "Unknown")),\(String(format: "%.0f", point.value))\n"
        }
        
        return csvString
    }
    
    func exportCSV(_ csvString: String) {
        let fileName = "HeartData.csv"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
            }
        } catch {
            print("Error writing CSV file: \(error)")
        }
    }
    
    func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    var body: some View {
        List {
            /*
            Section(footer: Text("Take heart rate measurements in the background. This feature will shorten your watch's battery life.")) {
                Toggle("Background Measurements", isOn: $backgroundHRMMeasurements)
            }
             */
            Section(footer: Text("Filter inconsistent data from your heart rate measurements.")) {
                Toggle("Filter Values", isOn: $filterHeartRateData)
            }
            Section(footer: Text("Export your heart rate data to a CSV file.")) {
                Button {
                    exportCSV(generateCSV(from: Array(heartPoints)))
                } label: {
                    Text("Export All Data")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    HeartSettingsView()
}
