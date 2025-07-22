//
//  SheetService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 01/07/25.
//

import Foundation
import SwiftData // TODO: Remove?

public struct SheetServiceResultType: Equatable {
    var sheetList: SheetListResponse?
    var message: SheetServiceMessage
    var status: ProgressStatus
}

public protocol SheetServiceProtocol {
    func getSheets() async throws -> [CachedSheet]
    func getSheet(sheetId: Int) async throws -> SheetDetailResponse
}

public final class SheetService: SheetServiceProtocol {
    
    // MARK: Private properties
    
    private let httpApiClient: HTTPApiClientProtocol
    private let infoPListLoader: InfoPlistLoaderProtocol
    private let keychainService: KeychainServiceProtocol
    private let swiftDataService: SwiftDataProtocol
    
    // MARK: Initializers

    /// Initializes the SheetService with dependencies for secure storage and HTTP communication.
    /// - Parameters:
    ///   - httpApiClient: The client responsible for making HTTP requests. Defaults to the shared dependency.
    ///   - infoPListLoader: The loader responsible for fetching configuration values from Info.plist. Defaults to the shared dependency.
    ///   - keychainService: The service responsible for accessing secure credentials. Defaults to the shared dependency.
    public init(
        httpApiClient: HTTPApiClientProtocol = Dependencies.shared.httpApiClient,
        infoPListLoader: InfoPlistLoaderProtocol = Dependencies.shared.infoPlistLoader,
        keychainService: KeychainServiceProtocol = Dependencies.shared.keychainService,
        swiftDataService: SwiftDataProtocol = Dependencies.shared.swiftDataService
    ) {
        self.httpApiClient = httpApiClient
        self.infoPListLoader = infoPListLoader
        self.keychainService = keychainService
        self.swiftDataService = swiftDataService
    }
    
    // MARK: Public methods
    
    public func getSheets() async throws -> [CachedSheet] {
        let isInternetAvailable = await httpApiClient.isInternetAvailable()
                
        if isInternetAvailable {
            return try await getSheetsOnline()
        } else {
            return try await getSheetsOffline()
        }
    }
    
    private func getSheetsOnline() async throws -> [CachedSheet] {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )

        switch result {
        case .success(let data):
            do {
                var sheetListResponse = try JSONDecoder().decode(SheetListResponse.self, from: data)
                sheetListResponse = SheetListResponse(
                    pageNumber: sheetListResponse.pageNumber,
                    pageSize: sheetListResponse.pageSize,
                    totalPages: sheetListResponse.totalPages,
                    totalCount: sheetListResponse.totalCount,
                    data: sheetListResponse.data.sorted(by: { $0.name < $1.name })
                )
                print("✅ Fetched \(sheetListResponse.data.count) sheets on page \(sheetListResponse.pageNumber)")
                sheetListResponse.data.forEach { print("- \($0.name)") }
                
                try await storeSheetsOffline(sheetListResponse: sheetListResponse)
                
                var result: [CachedSheet] = []
                
                for sheet in sheetListResponse.data {
                    result.append(CachedSheet(id: sheet.id, modifiedAt: sheet.modifiedAt, name: sheet.name))
                }
                
                return result
            } catch {
                print("⚠️ Decoding error: \(error)")
                throw NSError(domain: error.localizedDescription, code: 0)
            }
        case .failure(let error):
            print("❌ Failed to list sheets: \(error)")
            throw NSError(domain: error.localizedDescription, code: 0)
        }
    }
    
    private func storeSheetsOffline(sheetListResponse: SheetListResponse) async throws {
        try await MainActor.run {
            // Store response in SwiftData
            let context = swiftDataService.modelContext

            // Clear old entries
            let existing = try context.fetch(FetchDescriptor<CachedSheet>())
            existing.forEach { context.delete($0) }

            // Save new entries
            for sheet in sheetListResponse.data {
                let cache = CachedSheet(id: sheet.id, modifiedAt: sheet.modifiedAt, name: sheet.name)
                context.insert(cache)
            }
            
            print("✅ Sheets stored on SwiftData")
        }
    }
    
    private func getSheetsOffline() async throws -> [CachedSheet] {
        try await MainActor.run {
            let context = swiftDataService.modelContext
            let descriptor = FetchDescriptor<CachedSheet>(sortBy: [SortDescriptor(\.name)])
            let results = try context.fetch(descriptor)

            guard !results.isEmpty else {
                throw NSError(domain: "No cached sheets found", code: 0)
            }

            print("📦 Loaded cached sheets (\(results.count))")
            return results
        }
    }
    
    public func getSheet(sheetId: Int) async throws -> SheetDetailResponse {
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

// MARK: SwiftDataService

public protocol SwiftDataProtocol {
    var modelContext: ModelContext { get }
}

public final class SwiftDataService: SwiftDataProtocol {
    public let sharedModelContainer: ModelContainer
    public var modelContext: ModelContext

    public init() {
        let schema = Schema([CachedSheet.self])
        let config = ModelConfiguration("SmartsheetOffline", schema: schema)
        self.sharedModelContainer = try! ModelContainer(for: schema, configurations: [config])
        self.modelContext = ModelContext(self.sharedModelContainer)
    }
}

@Model
final public class CachedSheet {
    public var id: Int
    public var modifiedAt: String
    public var name: String

    init(
        id: Int,
        modifiedAt: String,
        name: String
    ) {
        self.id = id
        self.modifiedAt = modifiedAt
        self.name = name
    }
}
