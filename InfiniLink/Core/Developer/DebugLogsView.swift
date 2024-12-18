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
    
    var body: some View {
        TabView(selection: $logSelection) {
            logs(for: .ble)
                .tabItem {
                    Label("BLE", systemImage: "radiowaves.right")
                }
                .tag("ble")
            logs(for: .app)
                .tabItem {
                    Label("App", systemImage: "doc")
                }
                .tag("app")
        }
        .navigationTitle("\(logSelection == "ble" ? "BLE" : NSLocalizedString("App", comment: "")) Logs")
    }
    
    func logs(for type: DebugLogTarget) -> some View {
        let logs = logManager.logs.filter({ $0.target == type })
        
        return VStack {
            if logs.isEmpty {
                Text("No Logs")
                    .foregroundStyle(.gray)
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 8) {
                            if let caller = log.caller {
                                Text(caller)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.gray)
                            }
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
                        .padding(12)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = "\(log.type.rawValue.capitalized) from \(log.caller): \(log.body)"
                            } label: {
                                Label("Copy", systemImage: "doc.on.clipboard")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DebugLogsView()
            .onAppear {
                #if DEBUG
                DebugLogManager.shared.logs.append(DebugLog(caller: "DebugLogsView", body: "This is a testing error, designed to be multiple lines long.", type: .error, target: .app))
                #endif
            }
    }
}
