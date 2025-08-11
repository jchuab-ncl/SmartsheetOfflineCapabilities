//
//  SheetService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 01/07/25.
//

import Foundation
import SwiftData

public protocol SheetServiceProtocol {
    var sheetWithUpdatesToPublishStorageRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> { get }
    var sheetWithUpdatesToPublishMemoryRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> { get }
    
    func getSheetList() async throws -> [CachedSheetDTO]
    func getSheetListHasUpdatesToPublish() async throws
    func getSheetContent(sheetId: Int) async throws -> SheetContentDTO
    func addSheetWithUpdatesToPublish_Storage(sheetId: Int, name: String, newValue: String, oldValue: String, rowId: Int, columnId: Int) async throws
    func addSheetWithUpdatesToPublishInMemoryRepo(sheet: CachedSheetHasUpdatesToPublishDTO)
    func removeSheetHasUpdatesToPublish(sheetId: Int) async throws
    func commitMemoryToStorage(sheetId: Int) async throws
    func pushChangesToApi(sheetId: Int) async throws
}

public final class SheetService: SheetServiceProtocol {
    // MARK: Private properties
    
    private var modelContext: ModelContext
    private let httpApiClient: HTTPApiClientProtocol
    private let infoPListLoader: InfoPlistLoaderProtocol
    private let keychainService: KeychainServiceProtocol
        
    /// Used to set the value locally
    @Protected private(set) var protectedSheetHasUpdatesToPublishStorageRepo: [CachedSheetHasUpdatesToPublishDTO] = []
    
    @Protected private(set) var protectedSheetHasUpdatesToPublishMemoryRepo: [CachedSheetHasUpdatesToPublishDTO] = []
    
    // MARK: Public properties
    
    /// The memory instance of updates to publish
    /// Used to observe changes externally
    public var sheetWithUpdatesToPublishMemoryRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> {
        $protectedSheetHasUpdatesToPublishMemoryRepo
    }
    
    /// The stored instance of updates to publish
    /// Used to observe changes externally
    public var sheetWithUpdatesToPublishStorageRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> {
        $protectedSheetHasUpdatesToPublishStorageRepo
    }
    
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
    
    public func getSheetListHasUpdatesToPublish() async throws {
        try await MainActor.run {
            let context = modelContext
            let descriptor = FetchDescriptor<CachedSheetHasUpdatesToPublish>(sortBy: [SortDescriptor(\.name)])
            let results = try context.fetch(descriptor)

            guard !results.isEmpty else {
                print("No sheets with updates to publish found")
                protectedSheetHasUpdatesToPublishStorageRepo = []
                return
            }

            print("📦 Loaded sheets with updates to publish (\(results.count))")
            protectedSheetHasUpdatesToPublishStorageRepo = results
                .map {
                    CachedSheetHasUpdatesToPublishDTO(from: $0)
                }
                .sorted { $0.sheetName < $1.sheetName }
        }
    }
    
    /// Retrieves detailed content for a specific sheet, either from the Smartsheet API or from local storage depending on network availability.
    /// - Parameter sheetId: The unique identifier of the sheet to retrieve.
    /// - Returns: A `CachedSheetContentDTO` object containing the full content of the requested sheet.
    /// - Throws: An error if the sheet cannot be fetched from either source.
    public func getSheetContent(sheetId: Int) async throws -> SheetContentDTO {
        var sheet: SheetContentDTO = .empty
        do {
            sheet = try await getSheetContentFromStorage(sheetId: sheetId)
        } catch {
            // If there's no sheet stored offline we try to download the sheet
            let isInternetAvailable = await httpApiClient.isInternetAvailable()
            if isInternetAvailable {
                sheet = try await getSheetContentOnline(sheetId: sheetId)
            } else {
                sheet = try await getSheetContentFromStorage(sheetId: sheetId)
            }
        }
        
        return sheet
    }
    
    public func addSheetWithUpdatesToPublish_Storage(
        sheetId: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowId: Int,
        columnId: Int
    ) async throws {
        do {
            let newItem = CachedSheetHasUpdatesToPublish(
                sheetId: sheetId,
                name: name,
                newValue: newValue,
                oldValue: oldValue,
                rowId: rowId,
                columnId: columnId
            )
            modelContext.insert(newItem)

            try modelContext.save()
            
            /// Calling this method to publish the changes
            try await getSheetListHasUpdatesToPublish()
            print("✅ Added sheet with pending updates: Name: \(name) SheetID: \(sheetId)")
        } catch {
            print("❌ Failed to add sheet with pending updates: Name: \(error) SheetID: \(sheetId)")
            throw error
        }
    }
    
    public func addSheetWithUpdatesToPublishInMemoryRepo(sheet: CachedSheetHasUpdatesToPublishDTO) {
        //TODO: Do not update if the oldValue == newValue
        
        // Look for an existing entry with same (sheetId, rowId, columnId)
        if let idx = protectedSheetHasUpdatesToPublishMemoryRepo.firstIndex(where: {
            $0.sheetId == sheet.sheetId &&
            $0.rowId == sheet.rowId &&
            $0.columnId == sheet.columnId
        }) {
            // Update only the newValue; keep the rest intact
            protectedSheetHasUpdatesToPublishMemoryRepo[idx].newValue = sheet.newValue
            print("ℹ️ Updated existing in-memory record for SheetID: \(sheet.sheetId), RowID: \(sheet.rowId), ColumnID: \(sheet.columnId), OldValue: \(sheet.oldValue) with new value: \(sheet.newValue)")
        } else {
            // Not found: append new record
            protectedSheetHasUpdatesToPublishMemoryRepo.append(sheet)
            print("ℹ️ Added new in-memory record for SheetID: \(sheet.sheetId), RowID: \(sheet.rowId), ColumnID: \(sheet.columnId), OldValue: \(sheet.oldValue) with value: \(sheet.newValue)")
        }
    }
    
    public func removeSheetHasUpdatesToPublish(sheetId: Int) async throws {
        do {
            let descriptor = FetchDescriptor<CachedSheetHasUpdatesToPublish>(
                predicate: #Predicate { $0.sheetId == sheetId }
            )

            let results = try modelContext.fetch(descriptor)
            
            guard !results.isEmpty else {
                print("ℹ️ No sheet with ID \(sheetId) found in updates to remove.")
                return
            }
            
            results.forEach { modelContext.delete($0) }
            try modelContext.save()
            
            // Refresh local list after removal
            try await getSheetListHasUpdatesToPublish()
            
            print("✅ Removed sheet with pending updates: SheetID: \(sheetId)")
        } catch {
            print("❌ Failed to remove sheet with pending updates: SheetID: \(sheetId), Error: \(error)")
            throw error
        }
    }
    
    public func commitMemoryToStorage(sheetId: Int) async throws {
        // Snapshot current in-memory items
        let pending = protectedSheetHasUpdatesToPublishMemoryRepo.filter({ $0.sheetId == sheetId })
        guard !pending.isEmpty else {
            print("ℹ️ No in-memory updates to commit.")
            return
        }

        print("➡️ Committing \(pending.count) in-memory update(s) to storage…")
        
        var currentItem: CachedSheetHasUpdatesToPublishDTO?
        
        do {
            for item in pending {
                currentItem = item
                
                try await addSheetWithUpdatesToPublish_Storage(
                    sheetId: item.sheetId,
                    name: item.sheetName,
                    newValue: item.newValue,
                    oldValue: item.oldValue,
                    rowId: item.rowId,
                    columnId: item.columnId
                )
                
                // Clear memory repo after attempting to store
                protectedSheetHasUpdatesToPublishMemoryRepo.removeAll(where: {
                    $0.sheetId == item.sheetId &&
                    $0.rowId == item.rowId &&
                    $0.columnId == item.columnId
                })
            }
            
            //TODO: WIP
            try await updateSheetContentOnStorage(sheetId: sheetId)
        } catch {
            if let currentItem = currentItem {
                print("❌ Failed to persist in-memory update — SheetID: \(currentItem.sheetId), RowID: \(currentItem.rowId), ColumnID: \(currentItem.columnId). Error: \(error)")
            }
        }
                        
        print("✅ Commit complete. Cleared in-memory repo.")
    }
    
    public func pushChangesToApi(sheetId: Int) async throws {
        // 1) Build payload from stored items for this sheet
        let items = protectedSheetHasUpdatesToPublishStorageRepo.filter { $0.sheetId == sheetId }
        guard !items.isEmpty else {
            print("ℹ️ No in-memory changes to push for sheet \(sheetId).")
            return
        }

        // Group by rowId -> array of cells to update
        let groupedByRow = Dictionary(grouping: items, by: { $0.rowId })

        // Minimal payload to match API (value-only cells). Extend if you need image/objectValue later.
        struct CellUpdate: Codable {
            let columnId: Int
            let value: String
        }
        struct RowUpdate: Codable {
            // Smartsheet accepts numeric; sample shows string. We'll encode as String to match the sample.
            let id: String
            let cells: [CellUpdate]
        }

        let rowsPayload: [RowUpdate] = groupedByRow.map { (rowId, cells) in
            RowUpdate(
                id: String(rowId),
                cells: cells.map { CellUpdate(columnId: $0.columnId, value: $0.newValue) }
            )
        }.sorted { $0.id < $1.id } // deterministic

        let encoder = JSONEncoder()
        // Keep the JSON compact like the curl; for debugging pretty print is handy:
        // encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let body = try encoder.encode(rowsPayload)

        // 2) Make request
        var headers = makeHeaders()
        headers["Content-Type"] = "application/json"

        let url = try baseSheetsURL(path: "/sheets/\(sheetId)/rows")

        let result = await httpApiClient.request(
            url: url,
            method: .PUT,
            headers: headers,
            queryParameters: nil,
            body: body,
            encoding: .json
        )

        // 3) Handle response
        switch result {
        case .success(let data):
            // Optionally log the response for debugging
            if let str = String(data: data, encoding: .utf8) {
                print("✅ Pushed \(items.count) update(s) to sheet \(sheetId). Response: \(str)")
            } else {
                print("✅ Pushed \(items.count) update(s) to sheet \(sheetId).")
            }
            
            // Remove only the items for this sheet from storage
            try await removePendingSheetContentFromStorage(sheetId: sheetId)
        case .failure(let error):
            print("❌ Failed to push updates for sheet \(sheetId): \(error)")
            throw NSError(domain: "PushChangesError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Failed to push changes to API: \(error)"
            ])
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
    
    //TODO: WIP
    private func updateSheetContentOnStorage(sheetId: Int) async throws {
        // For every item on sheetWithUpdatesToPublishStorageRepo where item.sheetId == sheetId
        // Obtain the CachedSheetContent where sheetId == CachedSheetContent.id
        // Obtain the CachedRow linked with the CachedSheetContent where the item.rowId == rowId
        // Obtain the CachedCell where CachedCell.columnId == item.colunmID
        // Update the CachedCell.value and CachedCell.displayValue with the values on item.newValue
        
        // Work only with items for this sheet
        let items = protectedSheetHasUpdatesToPublishStorageRepo.filter { $0.sheetId == sheetId }
        guard !items.isEmpty else {
            print("ℹ️ No stored updates to apply for sheet \(sheetId).")
            return
        }

        try await MainActor.run {
            let context = modelContext

            // Fetch the cached sheet content
            let descriptor = FetchDescriptor<CachedSheetContent>(predicate: #Predicate { $0.id == sheetId })
            guard let cachedSheet = try? context.fetch(descriptor).first else {
                print("❌ CachedSheetContent not found for sheetId \(sheetId).")
                return
            }

            var appliedCount = 0

            for item in items {
                // Find the row
                guard let row = cachedSheet.rows.first(where: { $0.id == item.rowId }) else {
                    print("⚠️ Row not found (rowId: \(item.rowId)) for sheetId \(sheetId). Skipping.")
                    continue
                }

                // Find the cell by columnId
                if let cell = row.cells.first(where: { $0.columnId == item.columnId }) {
                    cell.value = item.newValue
                    cell.displayValue = item.newValue
                    appliedCount += 1
                    print("✅ Updated cell — sheetId: \(sheetId), rowId: \(item.rowId), columnId: \(item.columnId) -> \"\(item.newValue)\"")
                } else {
                    print("⚠️ Cell not found (columnId: \(item.columnId)) for rowId \(item.rowId) in sheetId \(sheetId). Skipping.")
                }
            }

            do {
                try context.save()
                print("💾 Saved \(appliedCount) cell update(s) to SwiftData for sheetId \(sheetId).")
            } catch {
                print("❌ Failed saving updated sheet content for sheetId \(sheetId): \(error)")
                throw error
            }
        }
    }
    
    private func removePendingSheetContentFromStorage(sheetId: Int) async throws {
        try await MainActor.run {
            let context = modelContext
            // Fetch all pending update records for this sheet from storage
            let descriptor = FetchDescriptor<CachedSheetHasUpdatesToPublish>(
                predicate: #Predicate { $0.sheetId == sheetId }
            )
            do {
                let toDelete = try context.fetch(descriptor)
                guard !toDelete.isEmpty else {
                    print("ℹ️ No pending sheet content found in storage for sheetId \(sheetId). Nothing to remove.")
                    return
                }

                toDelete.forEach { context.delete($0) }
                try context.save()
                print("✅ Removed \(toDelete.count) pending update record(s) from storage for sheetId \(sheetId).")
            } catch {
                print("❌ Failed to remove pending sheet content from storage for sheetId \(sheetId): \(error)")
                throw error
            }

            // Also clear the in-memory mirror for this sheet (if any)
            protectedSheetHasUpdatesToPublishStorageRepo.removeAll { $0.sheetId == sheetId }
        }

        // Refresh published storage repo after mutation
        try? await getSheetListHasUpdatesToPublish()
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
