//
//  Keychain.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import Security

enum Keychain {
    private static let service = Bundle.main.bundleIdentifier ?? "InfiniLink"
    
    private static func query(_ account: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
    
    static func get(_ account: String) -> String? {
        var query = query(account)
        query[kSecReturnData as String] = true
        
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
    
    static func set(_ value: String?, for account: String) {
        SecItemDelete(query(account) as CFDictionary)
        guard let value else { return }
        
        var query = query(account)
        query[kSecValueData as String] = Data(value.utf8)
        // Plugins can run while the phone is locked
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            log("Failed to save keychain item: \(status)", caller: "Keychain")
        }
    }
}
