//
//  MockURLSession].swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation

@testable import SmartsheetOfflineCapabilities

/// A mock implementation of URLSessionProtocol for unit testing HTTPApiClient.
/// Allows simulation of network responses without real network activity.
class URLSessionMock: URLSessionProtocol {

    private let mockData: Data?
    private let mockResponse: URLResponse?
    private let mockError: Error?

    /// Initializes the mock session with predefined response data, response, and error.
    /// - Parameters:
    ///   - data: The mock data to return.
    ///   - response: The mock URLResponse to return.
    ///   - error: An optional error to throw instead of returning data/response.
    init(data: Data?, response: URLResponse?, error: Error?) {
        self.mockData = data
        self.mockResponse = response
        self.mockError = error
    }

    /// Simulates an async data task by returning the predefined result or throwing the mock error.
    /// - Parameter request: The request that would be made.
    /// - Returns: A tuple containing mock data and response.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }

        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }
}
