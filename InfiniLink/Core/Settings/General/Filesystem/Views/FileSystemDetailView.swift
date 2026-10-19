//
//  FileSystemDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import SwiftUI

struct FileSystemDetailView: View {
    @State private var settings: Settings?
    @State private var textData: String?
    @State private var csvData: [[String]]?
    
    @State private var isLoadingFile = true
    @State private var hasLoaded = false
    
    let path: String
    
    private var fileName: String {
        (path as NSString).lastPathComponent
    }
    private var isSettings: Bool {
        path == "/settings.dat"
    }
    
    func row(key: LocalizedStringKey, value: LocalizedStringKey) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
    
    var body: some View {
        Group {
            if isLoadingFile {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let settings {
                List {
                    row(key: "Display Timeout", value: "\(settings.screenTimeOut / 1000) Seconds")
                    row(key: "Brightness Level", value: {
                        switch settings.brightLevel {
                        case .Low:
                            return "Low"
                        case .Mid:
                            return "Mid"
                        case .High:
                            return "High"
                        }
                    }())
                    row(key: "Time Format", value: settings.clockType == .H12 ? "12 Hour" : "24 Hour")
                    row(key: "Steps Goal", value: "\(settings.stepsGoal)")
                    row(key: "Weather Format", value: settings.weatherFormat == .Imperial ? "Imperial" : "Metric")
                    row(key: "Hourly Chimes", value: {
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
                ScrollView {
                    VStack {
                        if let csvData {
                            VStack(spacing: 0) {
                                ForEach(Array(csvData.enumerated()), id: \.offset) { _, fields in
                                    HStack(spacing: 0) {
                                        ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                                            Text(field)
                                                .padding(6)
                                            Divider()
                                        }
                                    }
                                    .padding(6)
                                    Divider()
                                }
                            }
                        } else {
                            Text(textData ?? NSLocalizedString("This file couldn't be read.", comment: ""))
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            
            if isSettings {
                BLEFSHandler.shared.readSettings { settings in
                    self.settings = settings
                    isLoadingFile = false
                }
            } else {
                BLEFSHandler.shared.readFile(path) { data in
                    show(data)
                    isLoadingFile = false
                }
            }
        }
        .navigationTitle(isSettings ? "Settings" : fileName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func show(_ data: Data) {
        switch (fileName as NSString).pathExtension.lowercased() {
        case "txt":
            textData = String(data: data, encoding: .utf8)
        case "json":
            if let object = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
               let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]) {
                textData = String(decoding: pretty, as: UTF8.self)
            }
        case "csv":
            csvData = String(data: data, encoding: .utf8)?
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .map { $0.components(separatedBy: ",") }
        default:
            textData = NSLocalizedString("This file is not currently supported.", comment: "")
        }
    }
}
