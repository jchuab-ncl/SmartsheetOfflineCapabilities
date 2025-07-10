//
//  SheetService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 01/07/25.
//

import Foundation

public struct SheetServiceResultType: Equatable {
    var sheetList: SheetListResponse?
    var message: SheetServiceMessage
    var status: ProgressStatus
}

public protocol SheetServiceProtocol {
    func getSheets() async throws -> SheetListResponse
    func getSheet(sheetId: String) async throws -> SheetDetailResponse
}

public final class SheetService: SheetServiceProtocol {
    
    // MARK: Private properties
    
    private let httpApiClient: HTTPApiClientProtocol
    private let infoPListLoader: InfoPlistLoaderProtocol
    private let keychainService: KeychainServiceProtocol
    
    // MARK: Initializers

    /// Initializes the SheetService with dependencies for secure storage and HTTP communication.
    /// - Parameters:
    ///   - httpApiClient: The client responsible for making HTTP requests. Defaults to the shared dependency.
    ///   - infoPListLoader: The loader responsible for fetching configuration values from Info.plist. Defaults to the shared dependency.
    ///   - keychainService: The service responsible for accessing secure credentials. Defaults to the shared dependency.
    public init(
        httpApiClient: HTTPApiClientProtocol = Dependencies.shared.httpApiClient,
        infoPListLoader: InfoPlistLoaderProtocol = Dependencies.shared.infoPlistLoader,
        keychainService: KeychainServiceProtocol = Dependencies.shared.keychainService
    ) {
        self.httpApiClient = httpApiClient
        self.infoPListLoader = infoPListLoader
        self.keychainService = keychainService
    }
    
    // MARK: Public methods
    
    public func getSheets() async throws -> SheetListResponse {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )

        switch result {
        case .success(let data):
            do {
                var decoded = try JSONDecoder().decode(SheetListResponse.self, from: data)
                decoded = SheetListResponse(
                    pageNumber: decoded.pageNumber,
                    pageSize: decoded.pageSize,
                    totalPages: decoded.totalPages,
                    totalCount: decoded.totalCount,
                    data: decoded.data.sorted(by: { $0.name < $1.name })
                )
                print("✅ Fetched \(decoded.data.count) sheets on page \(decoded.pageNumber)")
                decoded.data.forEach { print("- \($0.name)") }
                
                return decoded
            } catch {
                print("⚠️ Decoding error: \(error)")
                throw NSError(domain: error.localizedDescription, code: 0)
            }
        case .failure(let error):
            print("❌ Failed to list sheets: \(error)")
            throw NSError(domain: error.localizedDescription, code: 0)
        }
    }
    
    public func getSheet(sheetId: String) async throws -> SheetDetailResponse {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets/\(sheetId)"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )
        
        switch result {
        case .success(let data):
            do {
                let decoded = try JSONDecoder().decode(SheetDetailResponse.self, from: data)
                return decoded
            } catch {
                print("⚠️ Decoding error: \(error)")
                throw NSError(domain: error.localizedDescription, code: 0)
            }
        case .failure(let error):
            print("❌ Failed to get sheet: \(error)")
            throw NSError(domain: error.localizedDescription, code: 0)
        }
    }
    
    // MARK: Private methods

    private func makeHeaders() -> [String: String] {
        let token = keychainService.load(for: .smartsheetAccessToken) ?? ""
        return [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
    }

    private func baseSheetsURL(path: String) throws -> String {
        guard let baseUrl = infoPListLoader.get(.smartsheetsBaseUrl) else {
            throw NSError(domain: "Could not load base URL from Info.plist", code: 0)
        }
        
        return baseUrl + path
    }
}
