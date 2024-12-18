//
//  DebugLogManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/18/24.
//

import Foundation

enum DebugLogTarget: String {
    case ble
    case app
}

enum DebugLogType: String {
    case info
    case error
}

struct DebugLog: Identifiable {
    var id = UUID()
    let caller: String?
    let body: String
    let type: DebugLogType
    let target: DebugLogTarget
}

class DebugLogManager: ObservableObject {
    static let shared = DebugLogManager()
    
    @Published var logs: [DebugLog] = []
}

// Create a global function so we can log without calling LogManager
func log(_ log: String, type: DebugLogType = .error, caller: String? = nil, target: DebugLogTarget = .app) {
    let log = DebugLog(caller: caller, body: log, type: type, target: target)
    DebugLogManager.shared.logs.append(log)
}
