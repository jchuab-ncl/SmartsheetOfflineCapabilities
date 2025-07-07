//
//  SheetService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 01/07/25.
//


import Foundation

public struct SheetSource: Codable, Equatable {
    let id: Int
    let type: String
}

public struct Sheet: Codable, Equatable {
    let id: Int
    let accessLevel: String
    let createdAt: String
    let modifiedAt: String
    let name: String
    let permalink: String
    let version: Int?
    let source: SheetSource?
}

public struct SheetListResponse: Codable, Equatable {
    let pageNumber: Int
    let pageSize: Int
    let totalPages: Int
    let totalCount: Int
    let data: [Sheet]
}

public struct SheetServiceResultType: Equatable {
    var sheetList: SheetListResponse?
    var message: SheetServiceMessage
    var status: ProgressStatus
}

public protocol SheetServiceProtocol {
//    var resultType: Protected<SheetServiceResultType> { get }
    
    func listSheet() async throws -> SheetListResponse
}

public final class SheetService: SheetServiceProtocol {
    
    // MARK: Private properties
    
    private let keychainService: KeychainServiceProtocol
    private let httpApiClient: HTTPApiClientProtocol
    
    // MARK: Public properties
    
//    @Protected private(set) var currentResult: SheetServiceResultType = .init(sheetList: nil, message: .empty, status: .initial)
//    
//    public var resultType: Protected<SheetServiceResultType> {
//        $currentResult
//    }
    
    // MARK: Initializers

    /// Initializes the SheetService with dependencies for secure storage and HTTP communication.
    /// - Parameters:
    ///   - httpApiClient: The client responsible for making HTTP requests. Defaults to the shared dependency.
    ///   - keychainService: The service responsible for accessing secure credentials. Defaults to the shared dependency.
    public init(
        keychainService: KeychainServiceProtocol = Dependencies.shared.keychainService,
        httpApiClient: HTTPApiClientProtocol = Dependencies.shared.httpApiClient
    ) {
        self.keychainService = keychainService
        self.httpApiClient = httpApiClient
    }
    
    // MARK: Public methods
    public func listSheet() async throws -> SheetListResponse {
        let url = "https://api.smartsheet.com/2.0/sheets"
        
        let token = keychainService.load(for: .smartsheetAccessToken) ?? ""
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let result = await httpApiClient.request(
            url: url,
            method: .GET,
            headers: headers,
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
    
//    private func publish(_ msg: SheetServiceMessage, _ type: ProgressStatus) {
//        print("\(type.icon) SheetService: \(msg.description)")
//        currentResult = .init(message: msg, status: type)
//    }
//    
//    private func publishError(_ msg: SheetServiceMessage) throws {
//        print("❌ SheetService: \(msg.description)")
//        currentResult = .init(message: msg, status: .error)
//        throw msg
//    }
}
