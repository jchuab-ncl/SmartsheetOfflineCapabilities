//
//  HTTPApiClient.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

enum BodyEncoding {
    case json
    case urlEncoded
}

//struct HTTPRequest {
//    let url: URL
//    let method: HTTPMethod
//    let headers: [String: String]
//    let queryParameters: [String: String]?
//    let body: Data?
//}

/// A lightweight HTTP client for performing network requests using URLSession.
/// Supports injection of custom URLSessionProtocol for testability.
class HTTPApiClient: ObservableObject {

    private let session: URLSessionProtocol

    /// Creates a new instance of HTTPApiClient.
    /// - Parameter session: A URLSession-like instance for performing requests. Defaults to URLSession.shared.
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    /// Sends an HTTP request and returns the result asynchronously.
    /// - Parameters:
    ///   - url: The URL string for the request.
    ///   - method: The HTTP method to use.
    ///   - headers: The request headers.
    ///   - queryParameters: Optional query parameters to append to the URL.
    ///   - body: Optional HTTP body.
    /// - Returns: A result containing either the response data or an error.
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String],
        queryParameters: [String: String]? = nil,
        body: Data? = nil
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
}
