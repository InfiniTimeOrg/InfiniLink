//
//  PluginPolicy.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import CoreBluetooth

enum PluginPolicy {
    // Keep plugins away from firmware updates, and make them use the fs module for files
    static let blockedServices: Set<CBUUID> = [BLEUUID.dfuService]
    static let blockedCharacteristics: Set<CBUUID> = [BLEUUID.dfuControlPoint, BLEUUID.dfuPacket, BLEUUID.blefsTransfer]
    
    static func isBlocked(service: CBUUID) -> Bool {
        return blockedServices.contains(service)
    }
    
    static func isBlocked(characteristic: CBUUID) -> Bool {
        return blockedCharacteristics.contains(characteristic)
    }
    
    static func normalize(path: String) -> String? {
        let components = path.split(separator: "/")
        guard !components.contains(where: { $0 == ".." || $0 == "." }) else { return nil }
        
        return "/" + components.joined(separator: "/")
    }
    
    // InfiniLink manages these
    static func canWrite(path: String) -> Bool {
        let protectedDirectories = ["/fonts", "/images"]
        
        return path != "/settings.dat" && !protectedDirectories.contains { path == $0 || path.hasPrefix($0 + "/") }
    }
    
    // CBUUID(string:) crashes on bad input
    static func uuid(from value: String) -> CBUUID? {
        guard UUID(uuidString: value) != nil || value.range(of: "^([0-9a-fA-F]{4}|[0-9a-fA-F]{8})$", options: .regularExpression) != nil else { return nil }
        
        return CBUUID(string: value)
    }
}
