//
//  HTTPApiClient.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation
import Network

public enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

public enum BodyEncoding {
    case json
    case urlEncoded
}

/// Protocol for HTTP API Client functionality.
public protocol HTTPApiClientProtocol {
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String],
        queryParameters: [String: String]?,
        body: Data?,
        encoding: BodyEncoding
    ) async -> Result<Data, Error>
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String],
        queryParameters: [String: String]?
    ) async -> Result<Data, Error>

    func isInternetAvailable() async -> Bool
}

/// A lightweight HTTP client for performing network requests using URLSession.
/// Supports injection of custom URLSessionProtocol for testability.
public class HTTPApiClient: HTTPApiClientProtocol {
    private let session: URLSessionProtocol
    private let logService: LogServiceProtocol

    /// Creates a new instance of HTTPApiClient.
    /// - Parameter session: A URLSession-like instance for performing requests. Defaults to URLSession.shared.
    public init(
        session: URLSessionProtocol = URLSession.shared,
        logService: LogServiceProtocol = Dependencies.shared.logService
    ) {
        self.session = session
        self.logService = logService
    }

    /// Sends an HTTP request and returns the result asynchronously.
    /// - Parameters:
    ///   - url: The URL string for the request.
    ///   - method: The HTTP method to use.
    ///   - headers: The request headers.
    ///   - queryParameters: Optional query parameters to append to the URL.
    ///   - body: Optional HTTP body.
    ///   - encoding: The body encoding type. Defaults to .json.
    /// - Returns: A result containing either the response data or an error.
    public func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String] = [:],
        queryParameters: [String: String]? = nil,
        body: Data? = nil,
        encoding: BodyEncoding = .json
    ) async -> Result<Data, Error> {
        guard var components = URLComponents(string: url) else {
            return .failure(URLError(.badURL))
        }

        if let queryParameters = queryParameters {
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let finalURL = components.url else {
            return .failure(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.httpBody = body

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                return .failure(URLError(.badServerResponse))
            }

            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    /// Sends an HTTP request and returns the result asynchronously.
    /// - Parameters:
    ///   - url: The URL string for the request.
    ///   - method: The HTTP method to use.
    ///   - headers: The request headers.
    ///   - queryParameters: Optional query parameters to append to the URL.
    /// - Returns: A result containing either the response data or an error.
    public func request(
        url: String,
        method: HTTPMethod,
        headers: [String : String],
        queryParameters: [String : String]?
    ) async -> Result<Data, any Error> {
        return await self.request(
            url: url,
            method: method,
            headers: headers,
            queryParameters: queryParameters,
            body: nil,
            encoding: .json
        )
    }
    
    /// Asynchronously checks whether there is an active internet connection.
    /// - Returns: `true` if internet is reachable, `false` otherwise.
    public func isInternetAvailable() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "InternetMonitor")

            monitor.pathUpdateHandler = { path in
                let isConnected = path.status == .satisfied
                if isConnected {
                    self.logService.add(
                        text: "Internet connection is available.",
                        type: .info,
                        context: String(describing: type(of: self))
                    )
                } else {
                    self.logService.add(
                        text: "No internet connection.",
                        type: .info,
                        context: String(describing: type(of: self))
                    )
                }
                continuation.resume(returning: isConnected)
                monitor.cancel()
            }

            monitor.start(queue: queue)
        }
    }
}
