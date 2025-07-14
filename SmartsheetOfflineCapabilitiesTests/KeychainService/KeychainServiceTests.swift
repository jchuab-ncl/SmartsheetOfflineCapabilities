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
        _ = KeychainService().delete(for: .smartsheetAccessToken)
        super.tearDown()
    }
    
    func testSaveString() {
        let value = "Hello Keychain"
        XCTAssertTrue(KeychainService().save(value, for: .smartsheetAccessToken))
    }

    func testSaveAndLoadString() {
        let value = "Hello Keychain"
        XCTAssertTrue(KeychainService().save(value, for: .smartsheetAccessToken))
        let loaded = KeychainService().load(for: .smartsheetAccessToken)
        XCTAssertEqual(loaded, value)
    }

    func testDeleteString() {
        _ = KeychainService().save("DeleteMe", for: .smartsheetAccessToken)
        _ = KeychainService().delete(for: .smartsheetAccessToken)
        XCTAssertNil(KeychainService().load(for: .smartsheetAccessToken))
    }
        
    func testOverwriteStringValue() {
        let original = "FirstValue"
        let updated = "UpdatedValue"

        XCTAssertTrue(KeychainService().save(original, for: .smartsheetAccessToken))
        XCTAssertTrue(KeychainService().save(updated, for: .smartsheetAccessToken))

        let loaded = KeychainService().load(for: .smartsheetAccessToken)
        XCTAssertEqual(loaded, updated)
    }

    func testDeleteAllRemovesSavedItem() {
        let value = "TempToken"
        XCTAssertTrue(KeychainService().save(value, for: .smartsheetAccessToken))

        XCTAssertTrue(KeychainService().deleteAll())
        let result = KeychainService().load(for: .smartsheetAccessToken)
        XCTAssertNil(result)
    }
}
