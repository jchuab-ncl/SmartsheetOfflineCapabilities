//
//  InfoPListLoader.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation

enum InfoPlistLoaderKey: String {
    case smartsheetsClientId = "SMARTSHEETS_CLIENT_ID"
    case smartsheetsSecret = "SMARTSHEETS_SECRET"
    case smartsheetsBaseUrl = "SMARTSHEETS_BASE_URL"
}

/// A utility to safely retrieve values from Info.plist at runtime.
final class InfoPlistLoader {
    static let shared = InfoPlistLoader()

    private let infoDict: [String: Any]

    private init() {
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
