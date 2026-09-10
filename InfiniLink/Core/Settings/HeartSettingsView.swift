//
//  HeartSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI
import CoreData

private struct HeartExportRow: Sendable {
    let timestamp: Date?
    let value: Double
}

struct HeartSettingsView: View {
    @AppStorage("backgroundHRMMeasurements") var backgroundHRMMeasurements = false
    @AppStorage("filterHeartRateData") var filterHeartRateData = true
    @AppStorage("heartPointMarkMode") var heartPointMarkMode = "average"

    @State private var exportDate = Date()
    @State private var isExporting = false

    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>

    private var dayPoints: [HeartDataPoint] {
        let start = Calendar.current.startOfDay(for: exportDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start

        return heartPoints.filter {
            guard let timestamp = $0.timestamp else { return false }
            return timestamp >= start && timestamp < end
        }
    }

    nonisolated private static func generateCSV(from rows: [HeartExportRow]) -> String {
        var csvString = "Timestamp,Value\n"

        for row in rows {
            let timestamp = row.timestamp?.formatted() ?? "Unknown"
            csvString += "\(escapeField(timestamp)),\(String(format: "%.0f", row.value))\n"
        }

        return csvString
    }

    nonisolated private static func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    private func fileDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func export(_ points: [HeartDataPoint], fileName: String) {
        let rows = points.map { HeartExportRow(timestamp: $0.timestamp, value: $0.value) }
        isExporting = true

        Task {
            let csv = await Task.detached(priority: .userInitiated) {
                Self.generateCSV(from: rows)
            }.value

            await MainActor.run {
                self.presentShareSheet(csv, fileName: fileName)
                self.isExporting = false
            }
        }
    }

    private func presentShareSheet(_ csvString: String, fileName: String) {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)

            let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first,
               let root = keyWindow.rootViewController {
                root.present(activity, animated: true, completion: nil)
            }
        } catch {
            log("Error writing heart data CSV file: \(error.localizedDescription)", caller: "HeartSettingsView")
        }
    }

    var body: some View {
        List {
            Section(footer: Text("Filter inconsistent data from your heart rate measurements.")) {
                Toggle("Filter Values", isOn: $filterHeartRateData)
            }
            Section(footer: Text("Choose how the point mark on the heart rate chart is calculated.")) {
                Picker("Point Mark", selection: $heartPointMarkMode) {
                    Text("Average").tag("average")
                    Text("Median").tag("median")
                }
                .pickerStyle(.menu)
            }
            Section {
                DatePicker("Day", selection: $exportDate, in: ...Date(), displayedComponents: .date)
                if isExporting {
                    HStack {
                        ProgressView()
                        Text("Preparing export…")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Export Selected Day") {
                        export(dayPoints, fileName: "HeartData-\(fileDateString(exportDate)).csv")
                    }
                    .disabled(dayPoints.isEmpty)
                }
            } header: {
                Text("Export")
            } footer: {
                if dayPoints.isEmpty && !isExporting {
                    Text("There's no heart rate data recorded for the selected day.")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    HeartSettingsView()
}
