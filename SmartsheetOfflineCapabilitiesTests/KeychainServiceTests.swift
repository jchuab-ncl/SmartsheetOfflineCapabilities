//
//  KeychainServiceTests.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 23/06/25.
//

import XCTest
@testable import SmartsheetOfflineCapabilities

final class KeychainServiceTests: XCTestCase {

    struct TestCodable: Codable, Equatable {
        let id: Int
        let name: String
    }

    let testKey = "unit_test_key"

    override func tearDown() {
        _ = KeychainService.shared.delete(for: testKey)
        super.tearDown()
    }
    
    func testSaveString() {
        let value = "Hello Keychain"
        XCTAssertTrue(KeychainService.shared.save(value, for: testKey))
    }

    func testSaveAndLoadString() {
        let value = "Hello Keychain"
        XCTAssertTrue(KeychainService.shared.save(value, for: testKey))
        let loaded = KeychainService.shared.load(for: testKey)
        XCTAssertEqual(loaded, value)
    }

    func testDeleteString() {
        _ = KeychainService.shared.save("DeleteMe", for: testKey)
        _ = KeychainService.shared.delete(for: testKey)
        XCTAssertNil(KeychainService.shared.load(for: testKey))
    }
}
