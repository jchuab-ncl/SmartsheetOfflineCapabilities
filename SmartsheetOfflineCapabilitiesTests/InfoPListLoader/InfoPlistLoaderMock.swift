//
//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 30/06/25.
//

import XCTest

@testable import SmartsheetOfflineCapabilities

final class InfoPlistLoaderMock: InfoPlistLoaderProtocol {
    private let mockData: [String: Any]

    init(mockData: [String: Any]) {
        self.mockData = mockData
    }

    func get(_ key: InfoPlistLoaderKey) -> String? {
        return mockData[key.rawValue] as? String
    }
}
