//
//  KeychainServiceMock.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 14/07/25.
//

import XCTest

@testable import SmartsheetOfflineCapabilities

final class KeychainServiceMock: KeychainServiceProtocol {
    var mockData: [String: Any] = [:]
    
    func save(_ value: String, for key: SmartsheetOfflineCapabilities.KeychainKeys) -> Bool {
        mockData[key.rawValue] = value
        return true
    }
    
    func delete(for key: SmartsheetOfflineCapabilities.KeychainKeys) -> Bool {
        mockData.removeValue(forKey: key.rawValue)
        return true
    }
    
    func deleteAll() -> Bool {
        mockData.removeAll()
        return true
    }

    func load(for key: SmartsheetOfflineCapabilities.KeychainKeys) -> String? {
        return mockData[key.rawValue] as? String
    }
}
