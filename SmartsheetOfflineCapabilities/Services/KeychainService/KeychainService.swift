//
//  KeychainService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 23/06/25.
//

import Foundation
import Security

/// A protocol that defines secure storage operations for string values.
public protocol KeychainServiceProtocol {
    func save(_ value: String, for key: KeychainKeys) -> Bool
    func load(for key: KeychainKeys) -> String?
    func delete(for key: KeychainKeys) -> Bool
    func deleteAll() -> Bool
}

/// A service responsible for securely storing and retrieving data using the iOS Keychain.
/// Provides support for storing plain strings and Codable objects.
final class KeychainService: KeychainServiceProtocol {

    /// Saves a string value to the Keychain under the specified key.
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: The unique key to associate with the value.
    /// - Returns: `true` if the operation succeeded, otherwise `false`.
    func save(_ value: String, for key: KeychainKeys) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let service = Bundle.main.bundleIdentifier ?? "defaultService"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        
        if load(for: key) != nil {
            guard self.delete(for: key) else {
                return false
            }
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("❌ SecItemAdd failed with status: \(status)")
        }
        return status == errSecSuccess
    }

    /// Loads a string value from the Keychain for the specified key.
    /// - Parameter key: The key associated with the stored value.
    /// - Returns: The string value if found, otherwise `nil`.
    func load(for key: KeychainKeys) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == errSecSuccess,
              let data = dataTypeRef as? Data,
              let result = String(data: data, encoding: .utf8) else { return nil }

        return result
    }

    /// Deletes a value from the Keychain for the specified key.
    /// - Parameter key: The key whose value should be deleted.
    func delete(for key: KeychainKeys) -> Bool {
        let service = Bundle.main.bundleIdentifier ?? "defaultService"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: service
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("❌ SecItemDelete failed with status: \(status)")
        }
        
        return status == errSecSuccess
    }
    
    /// Deletes all generic password entries from the Keychain.
    /// This is typically used during a full reset or on first launch after reinstall.
    /// - Returns: `true` if the operation succeeded, otherwise `false`.
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("❌ SecItemDelete (all) failed with status: \(status)")
        }
        return status == errSecSuccess
    }
}
