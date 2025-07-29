//
//  SheetServiceTests.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 14/07/25.
//

import Combine
import Foundation
import XCTest

@testable import SmartsheetOfflineCapabilities

final class SheetServiceTests: XCTestCase {

    private var sheetService: SheetService!
    private var httpApiClientMock: HTTPApiClientMock!
    private var infoPlistLoaderMock: InfoPlistLoaderMock!
    private var keychainServiceMock: KeychainServiceMock!

    override func setUp() {
        super.setUp()

        httpApiClientMock = HTTPApiClientMock()
        infoPlistLoaderMock = InfoPlistLoaderMock(mockData: [
            InfoPlistLoaderKey.smartsheetsBaseUrl.rawValue: "smartsheetsBaseUrl"
        ])
        keychainServiceMock = KeychainServiceMock()

        sheetService = SheetService(
            httpApiClient: httpApiClientMock,
            infoPListLoader: infoPlistLoaderMock,
            keychainService: keychainServiceMock
        )
    }

    override func tearDown() {
        sheetService = nil
        httpApiClientMock = nil
        infoPlistLoaderMock = nil
        keychainServiceMock = nil
        super.tearDown()
    }

    func testGetSheetsSuccess() async throws {
        let sampleData = SheetList(
            pageNumber: 1,
            pageSize: 10,
            totalPages: 1,
            totalCount: 1,
            data: [Sheet(
                id: 1,
                accessLevel: "EDITOR",
                createdAt: "2025-07-10T12:00:00Z",
                modifiedAt: "2025-07-11T12:00:00Z",
                name: "Test Sheet",
                permalink: "https://example.com/sheet/1",
                version: 1,
                source: SheetSource(id: 100, type: "template")
            )]
        )
        
        httpApiClientMock.requestResult = .success(try JSONEncoder().encode(sampleData))

        let result = try await sheetService.getSheets()
        XCTAssertEqual(result.data.count, 1)
        XCTAssertEqual(result.data.first?.name, "Test Sheet")
    }

    func testGetSheetSuccess() async throws {
        let sampleSheet = SheetDetailResponseMock.makeMock()
        
        httpApiClientMock.requestResult = .success(try JSONEncoder().encode(sampleSheet))

        let result = try await sheetService.getSheet(sheetId: 1)
        XCTAssertEqual(result.name, sampleSheet.name)
    }
    
    func testGetSheetsFailure() async {
        httpApiClientMock.requestResult = .failure(NSError(domain: "TestError", code: -1))

        do {
            _ = try await sheetService.getSheets()
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "The operation couldn’t be completed. (TestError error -1.)")
        }
    }

    func testGetSheetFailure() async {
        httpApiClientMock.requestResult = .failure(NSError(domain: "TestError", code: -1))

        do {
            _ = try await sheetService.getSheet(sheetId: 123)
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "The operation couldn’t be completed. (TestError error -1.)")
        }
    }
}
