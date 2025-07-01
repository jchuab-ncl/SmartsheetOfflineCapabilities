//
//  InfoPListLoaderTest.swift
//  SmartsheetOfflineCapabilitiesTests
//
//  Created by Jeann Luiz Chuab on 30/06/25.
//

import XCTest
@testable import SmartsheetOfflineCapabilities

final class InfoPListLoaderTest: XCTestCase {
    func test_get_returnsCorrectValue_forValidKey() {
        let mockLoader = InfoPlistLoaderMock(mockData: [
            "SMARTSHEETS_CLIENT_ID": "test-client-id"
        ])

        let value = mockLoader.get(.smartsheetsClientId)
        XCTAssertEqual(value, "test-client-id")
    }

    func test_get_returnsNil_forMissingKey() {
        let mockLoader = InfoPlistLoaderMock(mockData: [:])

        let value = mockLoader.get(.smartsheetsSecret)
        XCTAssertNil(value)
    }

    func test_get_returnsCorrectValue_forBaseUrl() {
        let mockLoader = InfoPlistLoaderMock(mockData: [
            "SMARTSHEETS_BASE_URL": "https://example.com"
        ])

        let value = mockLoader.get(.smartsheetsBaseUrl)
        XCTAssertEqual(value, "https://example.com")
    }
}

