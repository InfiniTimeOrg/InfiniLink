//
//  ExportDataView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct ExportDataView: View {
    @ObservedObject var deviceManager = DeviceManager.shared

    @AppStorage("enableDeveloperMode") var enableDeveloperMode = false

    @State private var selectedTypes: Set<DataExporter.DataType> = [.heartRate, .steps, .battery, .sleep, .exercise]
    @State private var range = 1
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showError = false

    private var availableTypes: [DataExporter.DataType] {
        // Motion data is only useful for tuning sleep detection
        DataExporter.DataType.allCases.filter { ($0 != .motion || enableDeveloperMode) && ($0 != .sleep || SleepManager.shared.isSupported) }
    }

    private var startDate: Date? {
        switch range {
        case 0:
            return Calendar.current.date(byAdding: .day, value: -2, to: Date())
        case 1:
            return Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case 2:
            return Calendar.current.date(byAdding: .day, value: -30, to: Date())
        default:
            return nil
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Range", selection: $range) {
                    Text("Past 2 Days").tag(0)
                    Text("Past Week").tag(1)
                    Text("Past Month").tag(2)
                    Text("All Time").tag(3)
                }
            }
            Section {
                ForEach(availableTypes) { type in
                    Toggle(LocalizedStringKey(type.rawValue), isOn: Binding(
                        get: { selectedTypes.contains(type) },
                        set: { isOn in
                            if isOn {
                                selectedTypes.insert(type)
                            } else {
                                selectedTypes.remove(type)
                            }
                        }
                    ))
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Data is exported as CSV files in a zip for \(deviceManager.name).")
            }
            Section {
                Button {
                    export()
                } label: {
                    HStack {
                        Text("Export")
                        if isExporting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting || selectedTypes.isDisjoint(with: availableTypes))
            }
        }
        .navigationTitle("Export Data")
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
                    .ignoresSafeArea()
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Export Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("InfiniLink couldn't create the export. Please try again.")
        }
    }

    private func export() {
        guard let deviceId = deviceManager.pairedDeviceID else { return }

        isExporting = true
        exportURL = nil

        DataExporter().export(selectedTypes.intersection(availableTypes), since: startDate, deviceId: deviceId) { url in
            DispatchQueue.main.async {
                isExporting = false
                exportURL = url
                showShareSheet = url != nil
                showError = url == nil
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
}
