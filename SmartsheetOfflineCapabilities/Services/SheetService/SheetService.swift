//
//  SheetService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 01/07/25.
//

import Foundation
import SwiftData

public struct SheetServiceResultType: Equatable {
    var sheetList: SheetList?
    var message: SheetServiceMessage
    var status: ProgressStatus
}

public protocol SheetServiceProtocol {
    func getSheetList() async throws -> [CachedSheetDTO]
    func getSheetContent(sheetId: Int) async throws -> SheetContentDTO
}

public final class SheetService: SheetServiceProtocol {
    
    // MARK: Private properties
    
    private var modelContext: ModelContext
    private let httpApiClient: HTTPApiClientProtocol
    private let infoPListLoader: InfoPlistLoaderProtocol
    private let keychainService: KeychainServiceProtocol
    
    // MARK: Initializers

    /// Initializes the SheetService with dependencies for secure storage, HTTP communication, and local data persistence.
    /// - Parameters:
    ///   - httpApiClient: The client responsible for making HTTP requests. Defaults to the shared dependency.
    ///   - infoPlistLoader: The loader responsible for fetching configuration values from Info.plist. Defaults to the shared dependency.
    ///   - keychainService: The service responsible for accessing secure credentials. Defaults to the shared dependency.
    ///   - modelContext: The SwiftData model context used to initialize the sheet service.
    public init(
        httpApiClient: HTTPApiClientProtocol = Dependencies.shared.httpApiClient,
        infoPListLoader: InfoPlistLoaderProtocol = Dependencies.shared.infoPlistLoader,
        keychainService: KeychainServiceProtocol = Dependencies.shared.keychainService,
        modelContext: ModelContext
    ) {
        self.httpApiClient = httpApiClient
        self.infoPListLoader = infoPListLoader
        self.keychainService = keychainService
        self.modelContext = modelContext
    }
    
    // MARK: Public methods
    
    /// Retrieves a list of sheets either from the online Smartsheet API or from local storage depending on network availability.
    /// - Returns: An array of `CachedSheetDTO` representing the available sheets.
    /// - Throws: An error if both the network request and local fetch fail.
    public func getSheetList() async throws -> [CachedSheetDTO] {
        let isInternetAvailable = await httpApiClient.isInternetAvailable()
                
        if isInternetAvailable {
            return try await getSheetListOnline()
        } else {
            return try await getSheetListFromStorage()
        }
    }
    
    /// Retrieves detailed content for a specific sheet, either from the Smartsheet API or from local storage depending on network availability.
    /// - Parameter sheetId: The unique identifier of the sheet to retrieve.
    /// - Returns: A `CachedSheetContentDTO` object containing the full content of the requested sheet.
    /// - Throws: An error if the sheet cannot be fetched from either source.
    public func getSheetContent(sheetId: Int) async throws -> SheetContentDTO {
        let isInternetAvailable = await httpApiClient.isInternetAvailable()
                
        if isInternetAvailable {
            return try await getSheetContentOnline(sheetId: sheetId)
        } else {
            return try await getSheetContentFromStorage(sheetId: sheetId)
        }
    }
    
    // MARK: Private methods
    
    /// Fetches detailed information for a specific sheet from the Smartsheet API.
    /// - Parameter sheetId: The unique identifier of the sheet to retrieve.
    /// - Returns: A `CachedSheetContentDTO` object containing detailed information about the requested sheet.
    /// - Throws: An error if the network request fails or the data cannot be decoded.
    private func getSheetContentOnline(sheetId: Int) async throws -> SheetContentDTO {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets/\(sheetId)"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )
        
        switch result {
        case .success(let data):
            do {
                let sheetContent = try JSONDecoder().decode(SheetContent.self, from: data)
                
                try await storeSheetContent(sheetListResponse: sheetContent)
                
                // Convert stored sheet content to DTO to return
                
                let columns: [ColumnDTO] = (sheetContent.columns ?? []).map {
                    ColumnDTO(
                        id: $0.id,
                        index: $0.index,
                        title: $0.title,
                        type: $0.type,
                        systemColumnType: $0.systemColumnType ?? "",
                        hidden: $0.hidden ?? false,
                        width: $0.width,
                        options: $0.options ?? [],
                        contactOptions: $0.contactOptions?.asDTOs ?? []
                    ) }
                
                let rows = (sheetContent.rows ?? []).map { row in
                    RowDTO(
                        id: row.id,
                        rowNumber: row.rowNumber,
                        cells: (row.cells ?? []).map { cell in
                            CellDTO(columnId: cell.columnId, value: cell.value ?? "", displayValue: cell.displayValue ?? "")
                        }
                    )
                }
                
                return SheetContentDTO(
                    id: sheetContent.id,
                    name: sheetContent.name,
                    columns: columns,
                    rows: rows
                )
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
    
    private func getSheetListOnline() async throws -> [CachedSheetDTO] {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )

        switch result {
        case .success(let data):
            do {
                var sheetListResponse = try JSONDecoder().decode(SheetList.self, from: data)
                sheetListResponse = SheetList(
                    pageNumber: sheetListResponse.pageNumber,
                    pageSize: sheetListResponse.pageSize,
                    totalPages: sheetListResponse.totalPages,
                    totalCount: sheetListResponse.totalCount,
                    data: sheetListResponse.data.sorted(by: { $0.name < $1.name })
                )
                print("✅ Fetched \(sheetListResponse.data.count) sheets on page \(sheetListResponse.pageNumber)")
                sheetListResponse.data.forEach { print("- \($0.name)") }
                
                try await storeSheetList(sheetListResponse: sheetListResponse)
                
                let sortedData = sheetListResponse.data.sorted { $0.name < $1.name }
                let result = sortedData.map {
                    CachedSheetDTO(id: $0.id, modifiedAt: $0.modifiedAt, name: $0.name)
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
    
    private func storeSheetList(sheetListResponse: SheetList) async throws {
        try await MainActor.run {
            // Store response in SwiftData
            let context = modelContext

            // Clear old entries
            let existing = try context.fetch(FetchDescriptor<CachedSheet>())
            existing.forEach { context.delete($0) }

            // Save new entries
            for sheet in sheetListResponse.data {
                let cache = CachedSheet(id: sheet.id, modifiedAt: sheet.modifiedAt, name: sheet.name)
                context.insert(cache)
            }
            
            print("✅ SheetList stored on SwiftData")
        }
    }
    
    private func getSheetListFromStorage() async throws -> [CachedSheetDTO] {
        try await MainActor.run {
            let context = modelContext
            let descriptor = FetchDescriptor<CachedSheet>(sortBy: [SortDescriptor(\.name)])
            let results = try context.fetch(descriptor)

            guard !results.isEmpty else {
                throw NSError(domain: "No cached sheets found", code: 0)
            }

            print("📦 Loaded cached sheets (\(results.count))")
            return results
                .map { CachedSheetDTO(id: $0.id, modifiedAt: $0.modifiedAt, name: $0.name) }
                .sorted { $0.name < $1.name }
        }
    }
    
    private func getSheetContentFromStorage(sheetId: Int) async throws -> SheetContentDTO {
        let sheetContentDTO = try await MainActor.run {
            let context = modelContext
            
            // Testing
            let test = FetchDescriptor<CachedSheetContent>()
            let data = try context.fetch(test)
            print("LOG: ", data)
            
            let descriptor = FetchDescriptor<CachedSheetContent>(predicate: #Predicate { $0.id == sheetId })
            guard let cachedSheet = try context.fetch(descriptor).first else {
                print("❌ No cached sheet content found for id \(sheetId)")
                throw NSError(domain: "No cached sheet content found for id \(sheetId)", code: 0)
            }
            
            let columnsDTO = cachedSheet.columns.map {
                ColumnDTO(
                    id: $0.id,
                    index: $0.index,
                    title: $0.title,
                    type: ColumnType(rawValue: $0.type) ?? .textNumber,
                    systemColumnType: $0.systemColumnType ?? "",
                    hidden: $0.hidden ?? true,
                    width: $0.width,
                    options: $0.options.map { $0.value },
                    contactOptions: $0.contactOptions.asDTOs
                ) }
                .filter { !($0.hidden) }
                .sorted { $0.index < $1.index }
            
            let rowsDTO: [RowDTO] = cachedSheet.rows.map { row in
                RowDTO(
                    id: row.id,
                    rowNumber: row.rowNumber,
                    cells: row.cells.map { cell in
                        CellDTO(columnId: cell.columnId, value: cell.value, displayValue: cell.displayValue)
                    }
                )
            }.sorted { $0.rowNumber < $1.rowNumber }
            
            return SheetContentDTO(id: cachedSheet.id, name: cachedSheet.name, columns: columnsDTO, rows: rowsDTO)
        }
        
        return sheetContentDTO
    }
    
    private func storeSheetContent(sheetListResponse: SheetContent) async throws {
        try await MainActor.run {
            let context = modelContext

            // Clear existing data for this sheet if needed
            let existing = try context.fetch(FetchDescriptor<CachedSheetContent>())
            existing
              .filter { (sheet: CachedSheetContent) in sheet.id == sheetListResponse.id }
              .forEach { context.delete($0) }

            // Convert columns
            let cachedColumns: [CachedColumn] = (sheetListResponse.columns ?? []).map { (column: Column) in
                CachedColumn(
                    id: column.id,
                    index: column.index,
                    title: column.title,
                    type: column.type.rawValue,
                    systemColumnType: column.systemColumnType ?? "",
                    hidden: column.hidden ?? false,
                    width: column.width,
                    options: column.options ?? [],
                    contactOptions: column.contactOptions?.asCached ?? []
                )
            }

            // Convert rows and cells
            let cachedRows: [CachedRow] = (sheetListResponse.rows ?? []).map { (row: Row) in
                let cachedCells: [CachedCell] = (row.cells ?? []).map { (cell: SheetCell) in
                    CachedCell(columnId: cell.columnId, value: cell.value ?? "", displayValue: cell.displayValue ?? "")
                }
                return CachedRow(id: row.id, rowNumber: row.rowNumber, cells: cachedCells)
            }

            // Create CachedSheetContent model
            let cachedSheet = CachedSheetContent(
                id: sheetListResponse.id,
                name: sheetListResponse.name,
                columns: cachedColumns,
                rows: cachedRows
            )

            context.insert(cachedSheet)
            do {
                try context.save()
            } catch {
                print("✅ Error storing sheet content: \(sheetListResponse.name) in SwiftData. Error: \(error)")
            }
            print("✅ Sheet content: \(sheetListResponse.name) stored in SwiftData")
        }
    }
}
