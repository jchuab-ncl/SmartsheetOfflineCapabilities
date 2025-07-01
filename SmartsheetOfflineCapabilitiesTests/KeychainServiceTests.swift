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

    override func tearDown() {
        _ = KeychainService.shared.delete(for: .smartsheetAccessToken)
        super.tearDown()
    }
    
    func testSaveString() {
        let value = "Hello Keychain"
        XCTAssertTrue(KeychainService.shared.save(value, for: .smartsheetAccessToken))
    }

    func testSaveAndLoadString() {
        let value = "Hello Keychain"
        XCTAssertTrue(KeychainService.shared.save(value, for: .smartsheetAccessToken))
        let loaded = KeychainService.shared.load(for: .smartsheetAccessToken)
        XCTAssertEqual(loaded, value)
    }

    func testDeleteString() {
        _ = KeychainService.shared.save("DeleteMe", for: .smartsheetAccessToken)
        _ = KeychainService.shared.delete(for: .smartsheetAccessToken)
        XCTAssertNil(KeychainService.shared.load(for: .smartsheetAccessToken))
    }
        
    func testOverwriteStringValue() {
        let original = "FirstValue"
        let updated = "UpdatedValue"

        XCTAssertTrue(KeychainService.shared.save(original, for: .smartsheetAccessToken))
        XCTAssertTrue(KeychainService.shared.save(updated, for: .smartsheetAccessToken))

        let loaded = KeychainService.shared.load(for: .smartsheetAccessToken)
        XCTAssertEqual(loaded, updated)
    }

    func testDeleteAllRemovesSavedItem() {
        let value = "TempToken"
        XCTAssertTrue(KeychainService.shared.save(value, for: .smartsheetAccessToken))

        XCTAssertTrue(KeychainService.shared.deleteAll())
        let result = KeychainService.shared.load(for: .smartsheetAccessToken)
        XCTAssertNil(result)
    }
}
