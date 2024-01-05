//
//  DebugView.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/14/21.
//
//


import Foundation
import SwiftUI

struct DebugView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presMode
    
    @ObservedObject var logManager = DebugLogManager.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    @State var selection: DebugTab = .BLE
    
    func getLogsAndShare() {
        var items: String = """
"""
        switch selection {
        case .BLE:
            for entry in 0..<logManager.logFiles.bleLogEntries.count {
                items.append("\(logManager.logFiles.bleLogEntries[entry].date + " - " + logManager.logFiles.bleLogEntries[entry].message)\n")
            }
        case .DFU:
            for entry in 0..<logManager.logFiles.dfuLogEntries.count {
                items.append("\(logManager.logFiles.dfuLogEntries[entry].date + " - " + logManager.logFiles.dfuLogEntries[entry].message)\n")
            }
        case .App:
            for entry in 0..<logManager.logFiles.appLogEntries.count {
                items.append("\(logManager.logFiles.appLogEntries[entry].date + " - " + logManager.logFiles.appLogEntries[entry].message)\n")
            }
        }
        shareApp(text: items)
    }
    
    func setPageTitle() -> String {
        switch self.selection {
        case .BLE:
            return "BLE Logs"
        case .DFU:
            return "DFU Logs"
        case .App:
            return "App Logs"
        }
    }
    func logView(entries: [DebugLogManager.LogEntry]) -> some View {
        VStack {
            if entries.isEmpty {
                Text(NSLocalizedString("no_logs", comment: "No Logs"))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(0..<entries.count, id: \.self) { entry in
                            Text(entries[entry].date.isEmpty ? "" : entries[entry].date + " - " + entries[entry].message)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                                .cornerRadius(15)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    func tabBarItem(selection: Binding<DebugTab>, tab: DebugTab, imageName: String) -> some View {
        Group {
            if selection.wrappedValue == tab {
                VStack(spacing: 6) {
                    Image(systemName: imageName)
                    Text(tab.rawValue)
                }
                .imageScale(.large)
                .font(.body.weight(.semibold))
                .foregroundColor(colorScheme == .dark ? .white : .darkestGray)
                .cornerRadius(10)
                .padding(8)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: imageName)
                    Text(tab.rawValue)
                }
                .foregroundColor(Color.gray)
                .imageScale(.large)
                .padding(8)
            }
        }
    }
    func switchToTab(tab: DebugTab) {
        selection = tab
        
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
    }
    
    var tabBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                tabBarItem(selection: $selection, tab: .BLE, imageName: "radiowaves.right")
                    .onTapGesture {
                        switchToTab(tab: .BLE)
                    }
                    .frame(maxWidth: .infinity)
                
                tabBarItem(selection: $selection, tab: .DFU, imageName: "arrow.up.doc")
                    .onTapGesture {
                        switchToTab(tab: .DFU)
                    }
                    .frame(maxWidth: .infinity)
                
                tabBarItem(selection: $selection, tab: .App, imageName: "ant")
                    .onTapGesture {
                        switchToTab(tab: .App)
                    }
                    .frame(maxWidth: .infinity)
            }
            .padding(12)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                Text(setPageTitle())
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                    getLogsAndShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            switch selection {
            case .BLE:
                logView(entries: logManager.logFiles.bleLogEntries)
            case .DFU:
                logView(entries: logManager.logFiles.dfuLogEntries)
            case .App:
                logView(entries: logManager.logFiles.appLogEntries)
            }
            Divider()
            tabBar
        }
    }
}

enum DebugTab: String {
    case BLE
    case DFU
    case App
}
