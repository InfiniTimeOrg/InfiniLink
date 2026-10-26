//
//  Plugin.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import CryptoKit

enum PluginPermission: String, Codable, CaseIterable {
    case http = "HTTP"
    case filesystem = "FILESYSTEM"
    case volumeControl = "VOLUME_CONTROL"
    case mediaControl = "MEDIA_CONTROL"
    case location = "LOCATION"
    
    var title: String {
        switch self {
        case .http:
            return NSLocalizedString("Send HTTP requests", comment: "")
        case .filesystem:
            return NSLocalizedString("Read and write files on your watch", comment: "")
        case .volumeControl:
            return NSLocalizedString("Change your phone's volume", comment: "")
        case .mediaControl:
            return NSLocalizedString("Control and see what's playing in Apple Music", comment: "")
        case .location:
            return NSLocalizedString("Access your location", comment: "")
        }
    }
}

struct PluginParam: Codable, Hashable {
    enum Kind: String, Codable {
        case string
        case secret
        case int
        case boolean
    }
    
    let name: String
    let kind: Kind
    let defaultValue: String?
    
    func value(from raw: String?) -> Any {
        let raw = raw ?? defaultValue ?? ""
        
        switch kind {
        case .int:
            return Int(raw) ?? 0
        case .boolean:
            return raw == "true"
        case .string, .secret:
            return raw
        }
    }
}

struct PluginParseError: LocalizedError {
    let errorDescription: String?
    
    init(_ message: String) {
        errorDescription = message
    }
}

struct Plugin: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let author: String?
    let permissions: [PluginPermission]
    let params: [PluginParam]
    let checksum: String
    var downloadURL: URL?
    var enabled = false
    
    // PinePartner's header works too, so its plugins import as-is
    static func parse(_ source: String, downloadURL: URL? = nil) throws -> Plugin {
        let headers = ["// ==InfiniLink Plugin==", "// ==PinePartner Plugin=="]
        var lines = source.components(separatedBy: .newlines).makeIterator()
        
        guard let header = lines.next()?.trimmingCharacters(in: .whitespaces), headers.contains(header) else {
            throw PluginParseError(NSLocalizedString("Plugins must start with a \"// ==InfiniLink Plugin==\" header", comment: ""))
        }
        let footer = header.replacingOccurrences(of: "// ==", with: "// ==/")
        
        var id: String?
        var name: String?
        var description: String?
        var author: String?
        var permissions: [PluginPermission] = []
        var params: [PluginParam] = []
        var foundFooter = false
        
        while let line = lines.next()?.trimmingCharacters(in: .whitespaces), line.hasPrefix("//") {
            if line == footer {
                foundFooter = true
                break
            }
            
            let rest = line.dropFirst(2).trimmingCharacters(in: .whitespaces)
            guard !rest.isEmpty else { continue }
            guard let space = rest.firstIndex(of: " ") else {
                throw PluginParseError(String(format: NSLocalizedString("Invalid header line: %@", comment: ""), line))
            }
            let value = rest[rest.index(after: space)...].trimmingCharacters(in: .whitespaces)
            
            switch rest[..<space] {
            case "@id":
                id = value
            case "@name":
                name = value
            case "@description":
                description = value
            case "@author":
                author = value
            case "@permission":
                guard let permission = PluginPermission(rawValue: value) else {
                    throw PluginParseError(String(format: NSLocalizedString("Unsupported permission: %@", comment: ""), value))
                }
                permissions.append(permission)
            case "@param":
                guard let param = parseParam(value) else {
                    throw PluginParseError(String(format: NSLocalizedString("Invalid parameter: %@", comment: ""), value))
                }
                params.append(param)
            default:
                throw PluginParseError(String(format: NSLocalizedString("Unknown header key: %@", comment: ""), String(rest[..<space])))
            }
        }
        
        guard foundFooter else {
            throw PluginParseError(NSLocalizedString("Missing plugin footer", comment: ""))
        }
        guard let name else {
            throw PluginParseError(NSLocalizedString("Missing plugin name", comment: ""))
        }
        guard let id, id.range(of: "^[a-zA-Z0-9\\-_.]+$", options: .regularExpression) != nil else {
            throw PluginParseError(NSLocalizedString("Missing or invalid plugin ID", comment: ""))
        }
        
        let checksum = SHA256.hash(data: Data(source.utf8)).map { String(format: "%02x", $0) }.joined()
        
        return Plugin(id: id, name: name, description: description, author: author, permissions: permissions, params: params, checksum: checksum, downloadURL: downloadURL)
    }
    
    // "type name [default]"
    private static func parseParam(_ value: String) -> PluginParam? {
        let parts = value.split(separator: " ").map(String.init)
        guard (2...3).contains(parts.count), let kind = PluginParam.Kind(rawValue: parts[0]) else { return nil }
        guard parts[1].range(of: "^[a-zA-Z0-9_]+$", options: .regularExpression) != nil else { return nil }
        
        return PluginParam(name: parts[1], kind: kind, defaultValue: parts.count == 3 ? parts[2] : nil)
    }
}
