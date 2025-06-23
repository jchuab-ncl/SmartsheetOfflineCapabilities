//
//  HTTPApiClientTests.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import XCTest
@testable import SmartsheetOfflineCapabilities

final class HTTPApiClientTests: XCTestCase {
    
    func test_successfulGETRequest_returnsData() async throws {
        let expectedData = "test".data(using: .utf8)!
        let mockSession = URLSessionMock(
            data: expectedData,
            response:
                HTTPURLResponse(
                    url: URL(string: "https://example.com")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                ),
            error: nil
        )
        
        let client = HTTPApiClient(session: mockSession)
        
        let result = await client.request(
            url: "https://example.com",
            method: .GET,
            headers: [:],
            queryParameters: nil,
            body: nil
        )
        
        switch result {
        case .success(let data):
            XCTAssertEqual(data, expectedData)
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }
    
    func test_serverError_returnsFailure() async throws {
        let mockSession = URLSessionMock(
            data: nil,
            response: HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            ),
            error: nil
        )
        let client = HTTPApiClient(session: mockSession)
        
        let result = await client.request(
            url: "https://example.com",
            method: .GET,
            headers: [:],
            queryParameters: nil,
            body: nil
        )
        
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }
    
    func test_requestError_returnsFailure() async throws {
        let mockError = URLError(.notConnectedToInternet)
        let mockSession = URLSessionMock(data: nil, response: nil, error: mockError)
        let client = HTTPApiClient(session: mockSession)
        
        let result = await client.request(
            url: "https://example.com",
            method: .GET,
            headers: [:],
            queryParameters: nil,
            body: nil
        )
        
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error as URLError):
            XCTAssertEqual(error.code, .notConnectedToInternet)
        default:
            XCTFail("Unexpected error type")
        }
    }
}
