//
//  InfoPListLoader.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation

public enum InfoPlistLoaderKey: String {
    case smartsheetsClientId = "SMARTSHEETS_CLIENT_ID"
    case smartsheetsSecret = "SMARTSHEETS_SECRET"
    case smartsheetsAuthUrl = "SMARTSHEETS_AUTH_URL"
    case smartsheetsBaseUrl = "SMARTSHEETS_BASE_URL"
}

/// A protocol for loading configuration values from a property list (Info.plist).
public protocol InfoPlistLoaderProtocol {
    /// Retrieves the value associated with the specified key.
    /// - Parameter key: The key for the value to retrieve.
    /// - Returns: A string value if found, otherwise nil.
    func get(_ key: InfoPlistLoaderKey) -> String?
}

/// A concrete implementation of `InfoPlistLoading` for accessing Info.plist values at runtime.
final class InfoPlistLoader: InfoPlistLoaderProtocol {
    private let infoDict: [String: Any]

    /// Initializes the loader by reading from the app's main bundle Info.plist.
    init() {
        self.infoDict = Bundle.main.infoDictionary ?? [:]
    }

    /// Retrieves a value for the given key from Info.plist.
    /// - Parameter key: The plist key to retrieve.
    /// - Returns: The string value if it exists and is of type String.
    func get(_ key: InfoPlistLoaderKey) -> String? {
        let value = infoDict[key.rawValue] as? String
        if value == nil {
            print("⚠️ Missing value for Info.plist key: \(key.rawValue)")
        }
        return value
    }
}
