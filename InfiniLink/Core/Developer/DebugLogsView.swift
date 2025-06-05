//
//  DebugLogsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/18/24.
//

import SwiftUI

struct DebugLogsView: View {
    @ObservedObject var logManager = DebugLogManager.shared
    
    @AppStorage("logSelection") var logSelection = "ble"
    
    @State private var searchText = ""
    
    var body: some View {
        TabView(selection: $logSelection) {
            logs(for: .app)
                .tabItem {
                    Label("App", systemImage: "doc")
                }
                .tag("app")
            logs(for: .ble)
                .tabItem {
                    Label("BLE", systemImage: "radiowaves.right")
                }
                .tag("ble")
            logs(for: .dfu)
                .tabItem {
                    Label("DFU", systemImage: "arrow.up.doc")
                }
                .tag("dfu")
        }
        .navigationTitle("\(logSelection == "ble" ? "BLE" : NSLocalizedString("App", comment: "")) Logs")
    }
    
    func logs(for type: DebugLogTarget) -> some View {
        var filteredLogs: [DebugLog] {
            return logManager.logs
                .filter({ $0.target == type })
                .filter({
                    if !searchText.isEmpty {
                        let query = searchText.lowercased()
                        let body = $0.body.lowercased()
                        let caller = $0.caller?.lowercased() ?? ""
                        
                        return body.contains(query) || caller.contains(query)
                    }
                    return true
                })
                .sorted(by: { log1, log2 in
                    return log1.date > log2.date
                })
        }
        
        return VStack {
            List {
                ForEach(filteredLogs) { log in
                    VStack(alignment: .leading, spacing: 8) {
                        Group {
                            let date = log.date.formatted(.dateTime.day().weekday().month().hour().minute().second())
                            if let caller = log.caller {
                                Text(caller + " • " + date)
                            } else {
                                Text(date)
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                        Text(log.body)
                        if log.type == .error {
                            let color = (log.type == .error ? Color.red : Color.orange)
                            
                            Text(log.type.rawValue.uppercased())
                                .font(.system(size: 10.5))
                                .padding(4)
                                .padding(.horizontal, 4)
                                .foregroundStyle(color)
                                .background {
                                    Capsule()
                                        .stroke(color, lineWidth: 2)
                                }
                                .clipShape(Capsule())
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .padding()
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = {
                                return "\(log.type.rawValue.capitalized) \(log.caller == nil ? "" : "from \(log.caller!)") at \(log.date.formatted()): \(log.body)"
                            }()
                        } label: {
                            Label("Copy", systemImage: "doc.on.clipboard")
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let logToRemove = filteredLogs[index]
                        if let originalIndex = logManager.logs.firstIndex(where: { $0.id == logToRemove.id }) {
                            logManager.logs.remove(at: originalIndex)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
        }
        .overlay {
            if filteredLogs.isEmpty {
                Text("No Logs")
                    .foregroundStyle(.gray)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    NavigationView {
        DebugLogsView()
            .onAppear {
#if DEBUG
                DebugLogManager.shared.logs.append(DebugLog(caller: "DebugLogsView", body: "This is a testing error, designed to be multiple lines long.", type: .error, target: .app, date: Date()))
#endif
            }
    }
}
