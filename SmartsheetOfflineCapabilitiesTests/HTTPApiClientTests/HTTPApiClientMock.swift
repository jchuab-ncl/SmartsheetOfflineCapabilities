//
//  HTTPApiClientMock.swift
//  SmartsheetOfflineCapabilitiesTests
//
//  Created by Jeann Luiz Chuab on 25/06/25.
//

import Foundation

@testable import SmartsheetOfflineCapabilities

final class HTTPApiClientMock: HTTPApiClientProtocol {
    var isInternetAvailableResult: Bool = true
    var requestResult: Result<Data, Error> = .failure(URLError(.notConnectedToInternet))
    var capturedRequests: [(url: String, method: HTTPMethod, headers: [String: String], queryParameters: [String: String]?, body: Data?, encoding: BodyEncoding)] = []
    
    func isInternetAvailable() async -> Bool {
        return isInternetAvailableResult
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String : String],
        queryParameters: [String : String]?,
        body: Data?,
        encoding: BodyEncoding
    ) async -> Result<Data, Error> {
        capturedRequests.append((url, method, headers, queryParameters, body, encoding))
        return requestResult
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String : String],
        queryParameters: [String : String]?
    ) async -> Result<Data, Error> {
        return await request(
            url: url,
            method: method,
            headers: headers,
            queryParameters: queryParameters,
            body: nil,
            encoding: .json
        )
    }
    
    static func mockTokenResponse() -> Data {
        let json = """
        {
            "access_token": "mock_access_token",
            "expires_in": 3600,
            "refresh_token": "mock_refresh_token",
            "token_type": "bearer"
        }
        """
        return Data(json.utf8)
    }
}
