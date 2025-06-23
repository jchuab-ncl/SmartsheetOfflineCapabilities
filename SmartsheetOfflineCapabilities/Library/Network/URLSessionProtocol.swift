//
//  URLSessionProtocol.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation

/// A protocol that abstracts URLSession for testing purposes.
/// It allows mocking URL requests in unit tests by conforming to this protocol.
public protocol URLSessionProtocol {
    /// Performs a network request and returns the resulting data and response.
    /// - Parameter request: The URLRequest to execute.
    /// - Returns: A tuple containing the response data and URLResponse.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
