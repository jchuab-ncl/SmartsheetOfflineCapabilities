//
//  SheetService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 01/07/25.
//

import Foundation
import SwiftData

// MARK: Helpers

// Payload structs supporting both value and contact updates
struct ContactObject: Codable {
    var objectType: String = "CONTACT"
    let email: String
    let name: String
}

struct MultiContactObjectValue: Codable {
    var objectType: String = "MULTI_CONTACT"
    let values: [ContactObject]
}

struct CellUpdate: Codable {
    let columnId: Int
    let value: String?
    let objectValue: MultiContactObjectValue?
    // For regular value updates: only "value" should be present
    init(columnId: Int, value: String) {
        self.columnId = columnId
        self.value = value
        self.objectValue = nil
    }
    // For contact updates: only "objectValue" should be present
    init(columnId: Int, contacts: [CachedSheetContactUpdatesToPublishDTO]) {
        self.columnId = columnId
        self.value = nil
        self.objectValue = MultiContactObjectValue(values: contacts.map { ContactObject(email: $0.email, name: $0.name) })
    }
    // Custom encoding to ensure only the correct key is sent
    enum CodingKeys: String, CodingKey {
        case columnId
        case value
        case objectValue
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(columnId, forKey: .columnId)
        // Only encode "value" if it's non-nil and objectValue is nil (regular update)
        if let value = value, objectValue == nil {
            try container.encode(value, forKey: .value)
        }
        // Only encode "objectValue" if it's non-nil and value is nil (contacts)
        if let objectValue = objectValue, value == nil {
            try container.encode(objectValue, forKey: .objectValue)
        }
    }
}

struct RowUpdate: Codable {
    var id: Int?
    var cells: [CellUpdate]
    
    init(id: Int, cells: [CellUpdate]) {
        self.id = id
        self.cells = cells
    }
    
    init(cells: [CellUpdate]) {
        self.cells = cells
    }
}

// Wrapper for discussion list responses
struct DiscussionListResponse: Codable {
    let pageNumber: Int
    let pageSize: Int
    let totalPages: Int
    let totalCount: Int
    let data: [DiscussionDTO]
}

// MARK: Protocol

public protocol SheetServiceProtocol {
    var sheetWithUpdatesToPublishStorageRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> { get }
    var sheetWithUpdatesToPublishMemoryRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> { get }
    var discussionsToPublishStorageRepo: Protected<[CachedSheetDiscussionToPublishDTO]> { get }
    //    var sheetDiscussionToPublishDTOMemoryRepo: Protected<[CachedSheetDiscussionToPublishDTO]> { get }
    
    var sheetContactToPublishStorageRepo: Protected<[CachedSheetContactUpdatesToPublishDTO]> { get }
    var serverInfoDTOMemoryRepo: Protected<ServerInfoDTO> { get }
    var conflictResultMemoryRepo: Protected<[Conflict]> { get }
//    var conflictSolvedMemoryRepo: Protected<[Conflict]> { get }
    
    /// Sheet List
    func getSheetList() async throws -> [CachedSheetDTO]
    func getSheetListHasUpdatesToPublish() async throws
    
    /// Sheet Content
    func getSheetContent(sheetId: Int) async throws -> SheetContentDTO
    func getSheetContentOnline(sheetId: Int, storeContent: Bool) async throws -> SheetContentDTO
    
    /// Discussions to publish
    func getDiscussionToPublishForSheet(sheetId: Int) async throws -> [DiscussionDTO]
    func commitSheetDiscussionToStorage(parentId: Int) async
    
    /// ServerInfo
    func getServerInfo() async throws
        
    /// Add methods
    func addSheetWithUpdatesToPublish_Storage(
        columnType: String,
        sheetId: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowNumber: Int,
        rowId: Int,
        columnName: String,
        columnId: Int,
        contacts: [CachedSheetContactUpdatesToPublishDTO]
    ) async throws
    func addSheetWithUpdatesToPublishInMemoryRepo(sheet: CachedSheetHasUpdatesToPublishDTO)
    func addDiscussionToPublishInMemoryRepo(sheet: CachedSheetDiscussionToPublishDTO)
    
    /// Remove methods
    func removeSheetHasUpdatesToPublish(sheetId: Int, rowId: Int?, columnId: Int?) async throws
    func removeDiscussionToPublishFromStorage(discussionDTO: DiscussionDTO) async throws
    
    /// Commit Memory to storage
    func commitMemoryToStorage(sheetId: Int) async throws
    
    /// Push to the API methods
    func pushSheetContentToApi(sheetId: Int) async throws
    func pushDiscussionsToApi(sheetId: Int) async throws
    
    /// Check for Conflicts
    func checkForConflicts(sheetId: Int) async throws
    func addSolvedConflict(conflict: Conflict)
}

// MARK: Implementation

public final class SheetService: SheetServiceProtocol {
    
    let httpApiClient: HTTPApiClientProtocol
    
    // MARK: Private properties
    
    var modelContext: ModelContext
    private let infoPListLoader: InfoPlistLoaderProtocol
    private let keychainService: KeychainServiceProtocol
    private let logService: LogServiceProtocol
        
    /// Used to set the value locally
    @Protected private(set) var protectedSheetHasUpdatesToPublishStorageRepo: [CachedSheetHasUpdatesToPublishDTO] = []
    @Protected private(set) var protectedSheetContactToPublishStorageRepo: [CachedSheetContactUpdatesToPublishDTO] = []
    @Protected private(set) var protectedDiscussionToPublishStorageRepo: [CachedSheetDiscussionToPublishDTO] = []
    @Protected private(set) var protectedSheetHasUpdatesToPublishMemoryRepo: [CachedSheetHasUpdatesToPublishDTO] = []
    @Protected private(set) var protectedDiscussionToPublishDTOMemoryRepo: [CachedSheetDiscussionToPublishDTO] = []
    @Protected private(set) var protectedServerInfoDTOMemoryRepo: ServerInfoDTO = .empty
    
    @Protected var protectedConflictResultMemoryRepo: [Conflict] = []
        
    // MARK: Public properties

    /// The stored instance of discussions to publish
    /// Used to observe changes externally
    public var sheetContactToPublishStorageRepo: Protected<[CachedSheetContactUpdatesToPublishDTO]> {
        $protectedSheetContactToPublishStorageRepo
    }
    
    public var discussionsToPublishStorageRepo: Protected<[CachedSheetDiscussionToPublishDTO]> {
        $protectedDiscussionToPublishStorageRepo
    }
    
    /// The stored instance of updates to publish
    /// Used to observe changes externally
    public var sheetWithUpdatesToPublishStorageRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> {
        $protectedSheetHasUpdatesToPublishStorageRepo
    }
    
    /// The memory instance of updates to publish
    /// Used to observe changes externally
    public var sheetWithUpdatesToPublishMemoryRepo: Protected<[CachedSheetHasUpdatesToPublishDTO]> {
        $protectedSheetHasUpdatesToPublishMemoryRepo
    }
    
    /// The stored instance of ServerInfo
    public var serverInfoDTOMemoryRepo: Protected<ServerInfoDTO> {
        $protectedServerInfoDTOMemoryRepo
    }
    
    /// The stored instance of ConflictResult
    public var conflictResultMemoryRepo: Protected<[Conflict]> {
        $protectedConflictResultMemoryRepo
    }
    
    // MARK: Initializers

    /// Initializes a new `SheetService`.
    ///
    /// This service coordinates all sheet-related operations, including:
    /// - Fetching sheet lists and content (online and offline)
    /// - Managing pending updates and discussions
    /// - Persisting and syncing data with the Smartsheet API
    /// - Handling conflict detection and resolution
    ///
    /// - Parameters:
    ///   - httpApiClient: Client responsible for performing HTTP requests.
    ///   - infoPListLoader: Loader used to read configuration values from `Info.plist`.
    ///   - keychainService: Service used to securely access authentication tokens.
    ///   - logService: Logging service used to record diagnostics, warnings, and errors.
    ///   - modelContext: SwiftData context used for local persistence.
    public init(
        httpApiClient: HTTPApiClientProtocol = Dependencies.shared.httpApiClient,
        infoPListLoader: InfoPlistLoaderProtocol = Dependencies.shared.infoPlistLoader,
        keychainService: KeychainServiceProtocol = Dependencies.shared.keychainService,
        logService: LogServiceProtocol = Dependencies.shared.logService,
        modelContext: ModelContext
    ) {
        self.httpApiClient = httpApiClient
        self.infoPListLoader = infoPListLoader
        self.keychainService = keychainService
        self.logService = logService
        self.modelContext = modelContext
    }
    
    // MARK: Public methods
    
    /// Retrieves a list of sheets either from the online Smartsheet API or from local storage depending on network availability.
    /// - Returns: An array of `CachedSheetDTO` representing the available sheets.
    /// - Throws: An error if both the network request and local fetch fail.
    public func getSheetList() async throws -> [CachedSheetDTO] {
        let isInternetAvailable = await httpApiClient.isInternetAvailable()

        /// The only sheet displayed
//        let idSheetFilter = 0
//         let idSheetFilter = 6397878290304900 // Sheet 10
        // 1310043925335940 // Sheet 05
        let idSheetFilter = 4576181282099076 // Main Sheet
        
        if isInternetAvailable {
            
            if idSheetFilter == 0 {
                return try await getSheetListOnline()
            } else {
                return try await getSheetOnline(sheetId: idSheetFilter)
            }
        } else {
            return try await getSheetListFromStorage()
        }
    }
    
    public func getSheetListHasUpdatesToPublish() async throws {
        try await MainActor.run {
            let context = modelContext

            // Fetch sheet cell updates
            let sheetDescriptor = FetchDescriptor<CachedSheetHasUpdatesToPublish>(sortBy: [SortDescriptor(\.name)])
            let sheetResults = try context.fetch(sheetDescriptor)

            // Fetch discussions to publish
            let discussionDescriptor = FetchDescriptor<CachedSheetDiscussionsToPublish>(sortBy: [SortDescriptor(\.dateTime)])
            let discussionResults = try context.fetch(discussionDescriptor)
            
            protectedDiscussionToPublishStorageRepo = discussionResults.map { .init(from: $0) }
            
            // Fetch contact updates
            let contactDescriptor = FetchDescriptor<CachedSheetContactUpdatesToPublish>(sortBy: [SortDescriptor(\.name)])
            let contactResults = try context.fetch(contactDescriptor)
            
            // Map & assign sheet updates
            let contactResultsDTOs = contactResults.map { CachedSheetContactUpdatesToPublishDTO(from: $0) }
            
            var sheetDTOs: [CachedSheetHasUpdatesToPublishDTO] = []
            for sheetResult in sheetResults {
                let contactFiltered = contactResultsDTOs.filter { $0.columnId == sheetResult.columnId && $0.rowId == sheetResult.rowId }
                sheetDTOs.append(CachedSheetHasUpdatesToPublishDTO(from: sheetResult, contacts: contactFiltered ))
            }

            if sheetDTOs.isEmpty {
                logService.add(
                    text: "No sheets with updates to publish found",
                    type: .info,
                    context: String(describing: type(of: self))
                )
            } else {
                logService.add(
                    text: "Loaded \(sheetDTOs.count) sheets with updates to publish ",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
            }
            protectedSheetHasUpdatesToPublishStorageRepo = sheetDTOs

            // Map & assign contact updates
            let contactDTOs = contactResults
                .map { CachedSheetContactUpdatesToPublishDTO(from: $0) }
                .sorted { $0.name < $1.name }

            if contactDTOs.isEmpty {
                logService.add(
                    text: "No contact updates to publish found",
                    type: .info,
                    context: String(describing: type(of: self))
                )
            } else {
                logService.add(
                    text: "Loaded contact updates to publish (\(contactDTOs.count))",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
            }
            protectedSheetContactToPublishStorageRepo = contactDTOs
        }
    }
    
    /// Retrieves detailed content for a specific sheet, either from the Smartsheet API or from local storage depending on network availability.
    /// - Parameter sheetId: The unique identifier of the sheet to retrieve.
    /// - Returns: A `CachedSheetContentDTO` object containing the full content of the requested sheet.
    /// - Throws: An error if the sheet cannot be fetched from either source.
    public func getSheetContent(sheetId: Int) async throws -> SheetContentDTO {
        var sheet: SheetContentDTO = .empty
        let isInternetAvailable = await httpApiClient.isInternetAvailable()
        do {
            /// If there's internet connection and there's no updates to publish, download last sheet content
            if isInternetAvailable && protectedSheetHasUpdatesToPublishStorageRepo.isEmpty {
                sheet = try await getSheetContentOnline(sheetId: sheetId)
            } else {
                sheet = try await getSheetContentFromStorage(sheetId: sheetId)
            }
        } catch {
            // If there's no sheet stored offline we try to download the sheet
            if isInternetAvailable {
                sheet = try await getSheetContentOnline(sheetId: sheetId)
            } else {
                sheet = try await getSheetContentFromStorage(sheetId: sheetId)
            }
        }
        
        return sheet
    }
    
    public func addSheetWithUpdatesToPublish_Storage(
        columnType: String,
        sheetId: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowNumber: Int,
        rowId: Int,
        columnName: String,
        columnId: Int,
        contacts: [CachedSheetContactUpdatesToPublishDTO]
    ) async throws {
        do {
            // Check for existing record for this (sheetId, rowId, columnId)
            let existingDescriptor = FetchDescriptor<CachedSheetHasUpdatesToPublish>(
                predicate: #Predicate { $0.sheetId == sheetId && $0.rowId == rowId && $0.columnId == columnId }
            )
            let existingItems = try modelContext.fetch(existingDescriptor)
            if let existing = existingItems.first {
                // Update its newValue
                existing.newValue = newValue
                logService.add(
                    text: "Updated existing sheet update record in storage for SheetID: \(sheetId), RowID: \(rowId), ColumnID: \(columnId) with new value: \(newValue)",
                    type: .info,
                    context: String(describing: type(of: self))
                )
            } else {
                // Not found: insert new
                let newItem = CachedSheetHasUpdatesToPublish(
                    columnType: columnType,
                    sheetId: sheetId,
                    name: name,
                    newValue: newValue,
                    oldValue: oldValue,
                    rowNumber: rowNumber,
                    rowId: rowId,
                    columnName: columnName,
                    columnId: columnId
                )
                modelContext.insert(newItem)
                logService.add(
                    text: "Inserted new sheet update record in storage for SheetID: \(sheetId), RowID: \(rowId), ColumnID: \(columnId) with value: \(newValue)",
                    type: .info,
                    context: String(describing: type(of: self))
                )
            }

            // Upsert contacts: remove existing entries for this (sheetId,rowId,columnId), then insert the new ones
            let existingContactsDescriptor = FetchDescriptor<CachedSheetContactUpdatesToPublish>(
                predicate: #Predicate { $0.sheetId == sheetId && $0.rowId == rowId && $0.columnId == columnId }
            )
            let existingContacts = try modelContext.fetch(existingContactsDescriptor)
            existingContacts.forEach { modelContext.delete($0) }

            let contactList: [CachedSheetContactUpdatesToPublish] = contacts.map { dto in
                CachedSheetContactUpdatesToPublish(
                    sheetId: dto.sheetId,
                    rowId: dto.rowId,
                    columnId: dto.columnId,
                    name: dto.name,
                    email: dto.email
                )
            }
            contactList.forEach { modelContext.insert($0) }

            try modelContext.save()

            /// Calling this method to publish the changes
            try await getSheetListHasUpdatesToPublish()
            logService.add(
                text: "Added/Updated sheet with pending updates: Name: \(name) SheetID: \(sheetId)",
                type: .debug,
                context: String(describing: type(of: self))
            )
        } catch {
            logService.add(
                text: "Failed to add sheet with pending updates: Name: \(error) SheetID: \(sheetId)",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw error
        }
    }
    
    public func addSheetDiscussionToPublishInStorage(item: CachedSheetDiscussionToPublishDTO) async throws {
        do {
            let newItem = CachedSheetDiscussionsToPublish(
                dateTime: item.dateTime,
                sheetId: item.sheetId,
                parentId: item.parentId,
                parentType: item.parentType.rawValue,
                firstNameUser: item.firstNameUser,
                lastNameUser: item.lastNameUser,
                comment: .init(text: item.comment.text)
            )
            
            modelContext.insert(newItem)
            try modelContext.save()
            
            /// Calling this method to publish the changes
            try await getSheetListHasUpdatesToPublish()
            logService.add(
                text: "Added discussion(s) with pending updates: SheetID: \(item.parentId)",
                type: .debug,
                context: String(describing: type(of: self))
            )
        } catch {
            logService.add(
                text: "Failed to add sheet discussions with pending updates: Name: \(error) SheetID: \(item.parentId)",
                type: .error,
                context: String(describing: type(of: self))
            )
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
            logService.add(
                text: "Updated existing in-memory record for SheetID: \(sheet.sheetId), RowID: \(sheet.rowId), ColumnID: \(sheet.columnId), OldValue: \(sheet.oldValue) with new value: \(sheet.newValue)",
                type: .debug,
                context: String(describing: type(of: self))
            )
        } else {
            // Not found: append new record
            protectedSheetHasUpdatesToPublishMemoryRepo.append(sheet)
            logService.add(
                text: "Added new in-memory record for SheetID: \(sheet.sheetId), RowID: \(sheet.rowId), ColumnID: \(sheet.columnId), OldValue: \(sheet.oldValue) with value: \(sheet.newValue)",
                type: .debug,
                context: String(describing: type(of: self))
            )
        }
    }
        
    //TODO: Since the comments/discussions are being directly stored on SwiftData we probably can remove that.
    public func addDiscussionToPublishInMemoryRepo(sheet: CachedSheetDiscussionToPublishDTO) {
        // Append new record
        protectedDiscussionToPublishDTOMemoryRepo.append(sheet)
        logService.add(
            text: "Added new in-memory discussion record for SheetID: \(sheet.parentId), Value: \(sheet.comment)",
            type: .debug,
            context: String(describing: type(of: self))
        )
    }
    
    public func removeSheetHasUpdatesToPublish(sheetId: Int, rowId: Int? = nil, columnId: Int? = nil) async throws {
        do {
            // Build predicate dynamically depending on parameters
            let descriptor: FetchDescriptor<CachedSheetHasUpdatesToPublish>
            if let rowId = rowId, let columnId = columnId {
                descriptor = FetchDescriptor(
                    predicate: #Predicate {
                        $0.sheetId == sheetId &&
                        $0.rowId == rowId &&
                        $0.columnId == columnId
                    }
                )
            } else if let rowId = rowId {
                descriptor = FetchDescriptor(
                    predicate: #Predicate {
                        $0.sheetId == sheetId &&
                        $0.rowId == rowId
                    }
                )
            } else if let columnId = columnId {
                descriptor = FetchDescriptor(
                    predicate: #Predicate {
                        $0.sheetId == sheetId &&
                        $0.columnId == columnId
                    }
                )
            } else {
                descriptor = FetchDescriptor(
                    predicate: #Predicate { $0.sheetId == sheetId }
                )
            }

            let results = try modelContext.fetch(descriptor)
            
            guard !results.isEmpty else {
                logService.add(
                    text: "No matching updates found for SheetID: \(sheetId), RowID: \(String(describing: rowId)), ColumnID: \(String(describing: columnId))",
                    type: .info,
                    context: String(describing: type(of: self))
                )
                return
            }
            
            results.forEach { modelContext.delete($0) }
            try modelContext.save()
            
            // Refresh local list after removal
            try await getSheetListHasUpdatesToPublish()
            
            logService.add(
                text: "Removed \(results.count) pending updates for SheetID: \(sheetId), RowID: \(String(describing: rowId)), ColumnID: \(String(describing: columnId))",
                type: .debug,
                context: String(describing: type(of: self))
            )
        } catch {
            logService.add(
                text: "Failed to remove sheet updates for SheetID: \(sheetId). Error: \(error)",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw error
        }
    }
    
    public func removeDiscussionToPublishFromStorage(discussionDTO: DiscussionDTO) async throws {
        do {
            let descriptor = FetchDescriptor<CachedSheetDiscussionsToPublish>(sortBy: [SortDescriptor(\.dateTime)])

            let results = try modelContext.fetch(descriptor)
                       
            guard let itemToDelete = results.first(where: { discussionDTO.id == $0.id }) else {
                logService.add(
                    text: "No matching discussion found for removal: \(discussionDTO)",
                    type: .info,
                    context: String(describing: type(of: self))
                )
                return
            }
            
            modelContext.delete(itemToDelete)
            
            try modelContext.save()

            try await getSheetListHasUpdatesToPublish()
            logService.add(
                text: "Removed discussion from storage for sheetId: \(discussionDTO.parentId ?? 0)",
                type: .debug,
                context: String(describing: type(of: self))
            )
        } catch {
            logService.add(
                text: "Error removing discussion: \(error)",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw error
        }
    }
    
    public func commitMemoryToStorage(sheetId: Int) async throws {
        await commitSheetContentToStorage(sheetId: sheetId)
        await commitSheetDiscussionToStorage(parentId: sheetId)
    }
    
    public func pushSheetContentToApi(sheetId: Int) async throws {
        // 1) Build payload from stored items for this sheet
        let items = protectedSheetHasUpdatesToPublishStorageRepo.filter { $0.sheetId == sheetId }
        let contactItems = protectedSheetContactToPublishStorageRepo.filter { $0.sheetId == sheetId }
        guard !items.isEmpty || !contactItems.isEmpty else {
            logService.add(
                text: "No in-memory changes to push for sheet \(sheetId).",
                type: .info,
                context: String(describing: type(of: self))
            )
            return
        }

        // Build rows dictionary: rowId -> [CellUpdate]
        var rows: [Int: [CellUpdate]] = [:]

        // Regular value updates
        for item in items where item.contacts.isEmpty {
            rows[item.rowId, default: []].append(CellUpdate(columnId: item.columnId, value: item.newValue))
        }

        // Contact updates, grouped by (rowId, columnId)
        struct RowColumnKey: Hashable { let rowId: Int; let columnId: Int }
        let contactsByRowAndColumn = Dictionary(grouping: contactItems, by: { RowColumnKey(rowId: $0.rowId, columnId: $0.columnId) })
        for (key, contacts) in contactsByRowAndColumn {
            rows[key.rowId, default: []].append(CellUpdate(columnId: key.columnId, contacts: contacts))
        }

        // Prepare final payload, sorted by row id
        // Sending the id only when the rowId is not zero, this means a new row was created locally
        let rowsPayload: [RowUpdate] = rows
            .sorted {
                $0.key > $1.key
            }
            .map { (rowId, cells) in
                if rowId <= 0 {
                    RowUpdate(cells: cells)
                } else {
                    RowUpdate(id: rowId, cells: cells)
                }
            }

        // Split into new and existing rows
        let newRowsPayload = rowsPayload.filter { $0.id == nil }
        let existingRowsPayload = rowsPayload.filter { $0.id != nil }

        let encoder = JSONEncoder()
        var headers = makeHeaders()
        headers["Content-Type"] = "application/json"
        let url = try baseSheetsURL(path: "/sheets/\(sheetId)/rows")

        var succeeded = true
        var errors: [String] = []

        // POST new rows (rowId == 0)
        if !newRowsPayload.isEmpty {
            let newBody = try encoder.encode(newRowsPayload)
            let postResult = await httpApiClient.request(
                url: url,
                method: .POST,
                headers: headers,
                queryParameters: nil,
                body: newBody,
                encoding: .json
            )
            switch postResult {
            case .success(let data):
                logService.add(
                    text: "POSTED \(newRowsPayload.count) new row(s) to sheet \(sheetId). Response: \(String(data: data, encoding: .utf8) ?? "N/A")",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
            case .failure(let error):
                let msg = "Failed to POST new rows for sheetId \(sheetId): \(describeHTTPError(error))"
                logService.add(
                    text: msg,
                    type: .error,
                    context: String(describing: type(of: self))
                )
                errors.append(msg)
                succeeded = false
            }
        }

        // PUT existing rows (rowId != 0)
        if !existingRowsPayload.isEmpty {
            let updateBody = try encoder.encode(existingRowsPayload)
            let putResult = await httpApiClient.request(
                url: url,
                method: .PUT,
                headers: headers,
                queryParameters: nil,
                body: updateBody,
                encoding: .json
            )
            switch putResult {
            case .success(let data):
                logService.add(
                    text: "PUT \(existingRowsPayload.count) existing row(s) to sheet \(sheetId). Response: \(String(data: data, encoding: .utf8) ?? "N/A")",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
            case .failure(let error):
                let msg = "Failed to PUT existing rows for sheetId \(sheetId): \(describeHTTPError(error))"
                logService.add(
                    text: msg,
                    type: .error,
                    context: String(describing: type(of: self))
                )
                errors.append(msg)
                succeeded = false
            }
        }

        if succeeded {
            try await removePendingSheetContentFromStorage(sheetId: sheetId)
        } else if !errors.isEmpty {
            throw NSError(
                domain: "PushSheetContentError",
                code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey: errors.joined(separator: "\n")
                ]
            )
        }
    }
    
    public func pushDiscussionsToApi(sheetId: Int) async throws {
        // Fetch pending discussions for this sheet
        let discussionsToPublish: [CachedSheetDiscussionToPublishDTO] = protectedDiscussionToPublishStorageRepo
            .filter { $0.sheetId == sheetId }
            .sorted(by: { $0.dateTime < $1.dateTime })
        
        guard !discussionsToPublish.isEmpty else {
            logService.add(
                text: "No pending discussions to push for sheet \(sheetId).",
                type: .info,
                context: String(describing: type(of: self))
            )
            return
        }

        struct DiscussionCreatePayload: Encodable {
            struct Comment: Encodable { let text: String }
            let comment: Comment
        }

        var headers = makeHeaders()
        headers["Content-Type"] = "application/json"

        let encoder = JSONEncoder()
        var succeededIDs = Set<Int>()
        var errors: [String] = []

        // Smartsheet API accepts exactly one discussion per request.
        // Send each DTO individually to the proper endpoint.
        for dto in discussionsToPublish {
            let payload = DiscussionCreatePayload(comment: .init(text: dto.comment.text))
            let body: Data
            do {
                body = try encoder.encode(payload)
            } catch {
                let msg = "Failed to encode discussion payload (id: \(dto.id)) for sheet \(sheetId): \(error)"
                logService.add(
                    text: msg,
                    type: .error,
                    context: String(describing: type(of: self))
                )
                errors.append(msg)
                continue
            }

            // Build endpoint depending on parent type (sheet vs row)
            let path: String
            switch dto.parentType {
            case .sheet:
                path = "/sheets/\(sheetId)/discussions"
            case .row:
                path = "/sheets/\(sheetId)/rows/\(dto.parentId)/discussions"
            }

            let url: String
            do {
                url = try baseSheetsURL(path: path)
            } catch {
                let msg = "Failed to build URL for discussion (id: \(dto.id)) — \(error)"
                logService.add(
                    text: msg,
                    type: .error,
                    context: String(describing: type(of: self))
                )
                errors.append(msg)
                continue
            }

            let result = await httpApiClient.request(
                url: url,
                method: .POST,
                headers: headers,
                queryParameters: nil,
                body: body,
                encoding: .json
            )

            switch result {
            case .success(let data):
                if let str = String(data: data, encoding: .utf8) {
                    logService.add(
                        text: "Pushed discussion id=\(dto.id) to \(path). Response: \(str)",
                        type: .debug,
                        context: String(describing: type(of: self))
                    )
                } else {
                    logService.add(
                        text: "Pushed discussion id=\(dto.id) to \(path).",
                        type: .debug,
                        context: String(describing: type(of: self))
                    )
                }
                succeededIDs.insert(dto.id)
            case .failure(let error):
                let msg = "Failed to push discussion id=\(dto.id) to \(path): \(describeHTTPError(error))"
                logService.add(
                    text: msg,
                    type: .error,
                    context: String(describing: type(of: self))
                )
                errors.append(msg)
            }
        }

        // Remove only the successfully posted items from storage
        let succeededIDsSnapshot = succeededIDs

        if !succeededIDsSnapshot.isEmpty {
            do {
                try await MainActor.run {
                    let context = modelContext
                    let descriptor = FetchDescriptor<CachedSheetDiscussionsToPublish>(
                        predicate: #Predicate { $0.sheetId == sheetId }
                    )
                    let toCheck = try context.fetch(descriptor)
                    let toDelete = toCheck.filter { succeededIDsSnapshot.contains($0.id) }
                    toDelete.forEach { context.delete($0) }
                    try context.save()

                    // Update the in-memory mirror
                    protectedDiscussionToPublishStorageRepo.removeAll {
                        succeededIDsSnapshot.contains($0.id)
                    }
                    logService.add(
                        text: "Removed \(toDelete.count) successfully posted discussion(s) from storage for sheetId \(sheetId).",
                        type: .debug,
                        context: String(describing: type(of: self))
                    )
                }
            } catch {
                let msg = "Failed to clean up discussions after post for sheetId \(sheetId): \(error)"
                logService.add(
                    text: msg,
                    type: .error,
                    context: String(describing: type(of: self))
                )
                errors.append(msg)
            }
        }

        // Refresh lists
        try? await getSheetListHasUpdatesToPublish()

        // If any errors occurred, surface them
        if !errors.isEmpty {
            throw NSError(domain: "PushDiscussionsError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: errors.joined(separator: "\n")
            ])
        }
    }
    
    /// Fetches detailed information for a specific sheet from the Smartsheet API.
    /// - Parameters:
    ///  -  sheetId: The unique identifier of the sheet to retrieve.
    ///  - storeContent: Indicates if the obtained value should be locally stored.
    /// - Returns: A `CachedSheetContentDTO` object containing detailed information about the requested sheet.
    /// - Throws: An error if the network request fails or the data cannot be decoded.
    public func getSheetContentOnline(sheetId: Int, storeContent: Bool = true) async throws -> SheetContentDTO {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets/\(sheetId)?include=format"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )
        
        switch result {
        case .success(let data):
            do {
                let sheetContent = try JSONDecoder().decode(SheetContent.self, from: data)
                                                                
                // Convert stored sheet content to DTO to return
                
                let columns: [ColumnDTO] = (sheetContent.columns ?? []).map {
                    ColumnDTO(
                        id: $0.id,
                        index: $0.index,
                        title: $0.title,
                        type: $0.type,
                        primary: $0.primary,
                        locked: $0.locked ?? false,
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
                            CellDTO(
                                columnId: cell.columnId,
                                conditionalFormat: cell.conditionalFormat,
                                value: cell.value ?? "",
                                displayValue: cell.displayValue ?? "",
                                format: cell.format
                            )
                        }
                    )
                }
                                
                let discussions = try await getDiscussionForSheetOnline(sheetId: sheetId)
                
                if storeContent {
                    try await storeSheetContent(sheetListResponse: sheetContent, discussions: discussions)
                }
                
                return SheetContentDTO(
                    id: sheetContent.id,
                    name: sheetContent.name,
                    columns: columns,
                    rows: rows,
                    discussions: discussions
                )
            } catch {
                if let raw = String(data: data, encoding: .utf8) {
                    logService.add(
                        text: "Decoding error: \(error)\nRaw: \(raw)",
                        type: .error,
                        context: String(describing: type(of: self))
                    )
                } else {
                    logService.add(
                        text: "Decoding error: \(error)",
                        type: .error,
                        context: String(describing: type(of: self))
                    )
                }
                throw error
            }
        case .failure(let error):
            logService.add(
                text: "Failed to get sheet: \(describeHTTPError(error))",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw NSError(domain: error.localizedDescription, code: 0)
        }
    }
    
    public func getDiscussionToPublishForSheet(sheetId: Int) async throws -> [DiscussionDTO] {

        var result: [DiscussionDTO] = []

        let resultOffline = try await getDiscussionToPublishFromStorage(sheetId: sheetId)

        result.append(contentsOf: resultOffline.map{
            DiscussionDTO(from: $0)
        })

        return result
    }
    
    public func commitSheetDiscussionToStorage(parentId: Int) async {
        let discussionToPublish = protectedDiscussionToPublishDTOMemoryRepo.filter({ $0.parentId == parentId })
        
        guard discussionToPublish.isNotEmpty else {
            logService.add(
                text: "No in-memory sheet discussions updates to commit.",
                type: .info,
                context: String(describing: type(of: self))
            )
            return
        }
        
        var currentItem: CachedSheetDiscussionToPublishDTO?
        
        do {
            for item in discussionToPublish {
                
                currentItem = item
                
                try await addSheetDiscussionToPublishInStorage(item: item)
                
                // Clear memory repo after attempting to store
                protectedDiscussionToPublishDTOMemoryRepo.removeAll(where: {
                    $0.parentId == item.parentId &&
                    $0.comment.id == item.comment.id
                })
            }
        } catch {
            if let currentItem = currentItem {
                logService.add(
                    text: "Failed to persist in-memory DISCUSSION update — SheetID: \(currentItem.parentId), Value: \(currentItem.comment.text). Error: \(error)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
            }
        }
    }
    
    public func getServerInfo() async throws {
        let isInternetAvailable = await httpApiClient.isInternetAvailable()
        
        do {
            if isInternetAvailable {
                try await getServerInfoOnline()
            } else {
                try await getServerInfoFromStorage()
            }
        } catch {
            logService.add(
                text: "ServerInfo data could not be retrieved. Error: \(error)",
                type: .error,
                context: String(describing: type(of: self))
            )
        }
    }
    
    private func getServerInfoOnline() async throws {
        do {
            let url = try baseSheetsURL(path: "/serverinfo")
            let result = await httpApiClient.request(
                url: url,
                method: .GET,
                headers: makeHeaders(),
                queryParameters: nil
            )
            switch result {
            case .success(let data):
                do {
                    let serverInfo = try JSONDecoder().decode(ServerInfoDTO.self, from: data)
                                        
                    protectedServerInfoDTOMemoryRepo = serverInfo
                    
                    /// Storing Server Info locally
                    try await addServerInfoIntoStorage(serverInfo)
                } catch {
                    if let raw = String(data: data, encoding: .utf8) {
                        logService.add(
                            text: "ServerInfo decode error: \(error)\nRaw: \(raw)",
                            type: .error,
                            context: String(describing: type(of: self))
                        )
                    } else {
                        logService.add(
                            text: "ServerInfo decode error: \(error)",
                            type: .error,
                            context: String(describing: type(of: self))
                        )
                    }
                    throw NSError(domain: "ServerInfoDecodeError", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to decode ServerInfo: \(error.localizedDescription)"
                    ])
                }
            case .failure(let error):
                logService.add(
                    text: "Failed to fetch ServerInfo: \(describeHTTPError(error))",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                throw NSError(domain: "ServerInfoNetworkError", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to fetch server info: \(describeHTTPError(error))"
                ])
            }
        } catch {
            logService.add(
                text: "Unexpected error in getServerInfoOnline: \(error)",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw NSError(domain: "ServerInfoUnexpectedError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unexpected error retrieving server info: \(error.localizedDescription)"
            ])
        }
    }
           
    // MARK: Private methods
    
    private func getServerInfoFromStorage() async throws {
        return try await MainActor.run {
            let context = modelContext
            let descriptor = FetchDescriptor<CachedServerInfoDTO>()
            let results = try context.fetch(descriptor)
            if let first = results.first {
                protectedServerInfoDTOMemoryRepo = first.toDTO()
            } else {
                logService.add(
                    text: "No cached ServerInfo found in storage.",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                throw NSError(domain: "NoCachedServerInfo", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "No cached ServerInfo found in storage."
                ])
            }
        }
    }
    
    private func addServerInfoIntoStorage(_ serverInfo: ServerInfoDTO) async throws {
        try await MainActor.run {
            let context = modelContext
            // Remove existing CachedServerInfo entries
            let existing = try context.fetch(FetchDescriptor<CachedServerInfoDTO>())
            existing.forEach { context.delete($0) }
            // Convert and insert new CachedServerInfo
            let cache = CachedServerInfoDTO(dto: serverInfo)
            context.insert(cache)
            do {
                try context.save()
                logService.add(
                    text: "ServerInfo stored in SwiftData",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
            } catch {
                logService.add(
                    text: "Error storing ServerInfo in SwiftData: \(error)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                throw error
            }
        }
    }
    
    private func getDiscussionForSheetOnline(sheetId: Int) async throws -> [DiscussionDTO] {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets/\(sheetId)/discussions?include=comments,attachments"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )

        switch result {
        case .success(let data):
            do {
                let decoded = try JSONDecoder().decode(DiscussionListResponse.self, from: data)
                return decoded.data
            } catch {
                logService.add(
                    text: "Decoding discussions failed: \(error)",
                    type: .warning,
                    context: String(describing: type(of: self))
                )
                throw NSError(domain: "DecodingError", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to decode discussions: \(error.localizedDescription)"
                ])
            }

        case .failure(let error):
            logService.add(
                text: "Failed to fetch discussions for sheet \(sheetId): \(describeHTTPError(error))",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw NSError(domain: "NetworkError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch discussions: \(describeHTTPError(error))"
            ])
        }
    }
    
    private func getDiscussionToPublishFromStorage(sheetId: Int) async throws -> [CachedSheetDiscussionToPublishDTO] {
        let result: [CachedSheetDiscussionToPublishDTO] = try await MainActor.run {
            let context = modelContext
            let descriptor = FetchDescriptor<CachedSheetDiscussionsToPublish>(sortBy: [SortDescriptor(\.dateTime)])
            
            let results = try context.fetch(descriptor)

            guard !results.isEmpty else {
                logService.add(
                    text: "No discussions to publish found for SheetId \(sheetId)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                return []
            }

            logService.add(
                text: "Loaded cached sheets (\(results.count))",
                type: .debug,
                context: String(describing: type(of: self))
            )
                                    
            let resultMap: [CachedSheetDiscussionToPublishDTO] = results
                .map { CachedSheetDiscussionToPublishDTO(
                    id: $0.id,
                    dateTime: $0.dateTime,
                    sheetId: $0.sheetId,
                    parentId: $0.parentId,
                    parentType: .init(rawValue: $0.parentType) ?? .sheet,
                    comment: .init(text: $0.comment?.text ?? ""),
                    firstNameUser: $0.firstNameUser,
                    lastNameUser: $0.lastNameUser)
                }
                .sorted { $0.dateTime < $1.dateTime }
           
            protectedDiscussionToPublishStorageRepo = resultMap
            
            return resultMap
        }
        
        return result
    }
    
    private func commitSheetContentToStorage(sheetId: Int) async {
        // Snapshot current in-memory items
        let sheetToPublish = protectedSheetHasUpdatesToPublishMemoryRepo.filter({ $0.sheetId == sheetId })
        guard sheetToPublish.isNotEmpty else {
            logService.add(
                text: "No in-memory sheet content updates to commit.",
                type: .info,
                context: String(describing: type(of: self))
            )
            return
        }

        logService.add(
            text: "Committing \(sheetToPublish.count) in-memory update(s) to storage…",
            type: .debug,
            context: String(describing: type(of: self))
        )
        
        var currentItem: CachedSheetHasUpdatesToPublishDTO?
                
        do {
            for item in sheetToPublish {
                currentItem = item
                
                try await addSheetWithUpdatesToPublish_Storage(
                    columnType: item.columnType,
                    sheetId: item.sheetId,
                    name: item.sheetName,
                    newValue: item.newValue,
                    oldValue: item.oldValue,
                    rowNumber: item.rowNumber,
                    rowId: item.rowId,
                    columnName: item.columnName,
                    columnId: item.columnId,
                    contacts: item.contacts
                )
                
                // Clear memory repo after attempting to store
                protectedSheetHasUpdatesToPublishMemoryRepo.removeAll(where: {
                    $0.sheetId == item.sheetId &&
                    $0.rowId == item.rowId &&
                    $0.columnId == item.columnId
                })
            }
                        
            /// WIP: Commenting this code, so we can have a instance of the original sheet, without user changes.
//            try await updateSheetContentOnStorage(sheetId: sheetId)
        } catch {
            if let currentItem = currentItem {
                logService.add(
                    text: "Failed to persist in-memory update — SheetID: \(currentItem.sheetId), RowID: \(currentItem.rowId), ColumnID: \(currentItem.columnId). Error: \(error)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
            }
        }
        logService.add(
            text: "Commit complete. Cleared in-memory repo.",
            type: .debug,
            context: String(describing: type(of: self))
        )
    }
    
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
    
    private func getSheetOnline(sheetId: Int) async throws -> [CachedSheetDTO] {
        let result = await httpApiClient.request(
            url: try baseSheetsURL(path: "/sheets/\(sheetId)"),
            method: .GET,
            headers: makeHeaders(),
            queryParameters: nil
        )
        
        switch result {
        case .success(let data):
            do {
                let sheetResponse = try JSONDecoder().decode(Sheet.self, from: data)
                
                let sheetData = [
                    Sheet(
                        id: sheetId,
                        accessLevel: "",
                        createdAt: sheetResponse.createdAt,
                        modifiedAt: sheetResponse.modifiedAt,
                        name: sheetResponse.name,
                        permalink: "",
                        version: nil,
                        source: nil
                    )
                ]
                
                try await storeSheetList(sheetList: sheetData)

                return [CachedSheetDTO(id: sheetId, modifiedAt: sheetResponse.modifiedAt, name: sheetResponse.name)]
                
            } catch {
            logService.add(
                text: "Decoding error: \(error)",
                type: .warning,
                context: String(describing: type(of: self))
            )
                throw NSError(domain: error.localizedDescription, code: 0)
            }
        case .failure(let error):
            logService.add(
                text: "Failed to list sheets: \(describeHTTPError(error))",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw NSError(domain: error.localizedDescription, code: 0)
        }
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
                logService.add(
                    text: "Fetched \(sheetListResponse.data.count) sheets on page \(sheetListResponse.pageNumber)",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
                sheetListResponse.data.forEach {
                    logService.add(
                        text: "- \($0.name)",
                        type: .debug,
                        context: String(describing: type(of: self))
                    )
                }
                
                try await storeSheetList(sheetList: sheetListResponse.data)

                let result = sheetListResponse.data.map {
                    CachedSheetDTO(id: $0.id, modifiedAt: $0.modifiedAt, name: $0.name)
                }
                return result
            } catch {
                logService.add(
                    text: "Decoding error: \(error)",
                    type: .warning,
                    context: String(describing: type(of: self))
                )
                throw NSError(domain: error.localizedDescription, code: 0)
            }
        case .failure(let error):
            logService.add(
                text: "Failed to list sheets: \(describeHTTPError(error))",
                type: .error,
                context: String(describing: type(of: self))
            )
            throw NSError(domain: error.localizedDescription, code: 0)
        }
    }
    
    private func storeSheetList(sheetList: [Sheet]) async throws {
        try await MainActor.run {
            // Store response in SwiftData
            let context = modelContext

            // Clear old entries
            let existing = try context.fetch(FetchDescriptor<CachedSheet>())
            existing.forEach { context.delete($0) }

            // Save new entries
            for sheet in sheetList {
                let cache = CachedSheet(id: sheet.id, modifiedAt: sheet.modifiedAt, name: sheet.name)
                context.insert(cache)
            }
            
            logService.add(
                text: "SheetList stored on SwiftData",
                type: .debug,
                context: String(describing: type(of: self))
            )
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

            logService.add(
                text: "Loaded cached sheets (\(results.count))",
                type: .debug,
                context: String(describing: type(of: self))
            )
            return results
                .map { CachedSheetDTO(id: $0.id, modifiedAt: $0.modifiedAt, name: $0.name) }
                .sorted { $0.name < $1.name }
        }
    }
    
    private func getSheetContentFromStorage(sheetId: Int) async throws -> SheetContentDTO {
        let sheetContentDTO = try await MainActor.run {
            let context = modelContext

            let descriptor = FetchDescriptor<CachedSheetContent>(predicate: #Predicate { $0.id == sheetId })
            guard let cachedSheet = try context.fetch(descriptor).first else {
                logService.add(
                    text: "No cached sheet content found for id \(sheetId)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                throw NSError(domain: "No cached sheet content found for id \(sheetId)", code: 0)
            }

            let columnsDTO: [ColumnDTO] = cachedSheet.columns.map {
                ColumnDTO(from: $0)
            }
            .filter { !($0.hidden) }
            .sorted { $0.index < $1.index }

            // Use var so we can append a new row if needed
            var rowsDTO: [RowDTO] = cachedSheet.rows.map { row in
                RowDTO(
                    id: row.id,
                    rowNumber: row.rowNumber,
                    cells: row.cells.map { cell in
                        CellDTO(
                            columnId: cell.columnId,
                            conditionalFormat: cell.conditionalFormat,
                            value: cell.value,
                            displayValue: cell.displayValue,
                            format: cell.format
                        )
                    }
                )
            }.sorted { $0.rowNumber < $1.rowNumber }

            // Add new row from local updates where rowId < 0, which means the row was added locally
            let pendingInserts = protectedSheetHasUpdatesToPublishStorageRepo
                .filter { $0.sheetId == sheetId && $0.rowId <= 0 }
                .sorted(by: { $0.rowNumber < $1.rowNumber })

            let groupedInserts = Dictionary(grouping: pendingInserts, by: { $0.rowId }).sorted(by: { $0.key > $1.key })

            for (rowId, updates) in groupedInserts {
                let cells = updates.map {
                    CellDTO(
                        columnId: $0.columnId,
                        conditionalFormat: nil,
                        value: $0.newValue,
                        displayValue: $0.newValue,
                        format: nil
                    )
                }

                let newRow = RowDTO(
                    id: rowId,
                    rowNumber: rowId * -1,
                    cells: cells
                )

                rowsDTO.append(newRow)
            }

            let discussionsDTO: [DiscussionDTO] = cachedSheet.discussions.map { discussion in
                DiscussionDTO(from: discussion)
            }

            return SheetContentDTO(
                id: cachedSheet.id,
                name: cachedSheet.name,
                columns: columnsDTO,
                rows: rowsDTO,
                discussions: discussionsDTO
            )
        }

        return sheetContentDTO
    }
    
    private func updateSheetContentOnStorage(sheetId: Int) async throws {
        // For every item on sheetWithUpdatesToPublishStorageRepo where item.sheetId == sheetId
        // Obtain the CachedSheetContent where sheetId == CachedSheetContent.id
        // Obtain the CachedRow linked with the CachedSheetContent where the item.rowId == rowId
        // Obtain the CachedCell where CachedCell.columnId == item.colunmID
        // Update the CachedCell.value and CachedCell.displayValue with the values on item.newValue
        
        // Work only with items for this sheet
        let items = protectedSheetHasUpdatesToPublishStorageRepo.filter { $0.sheetId == sheetId }
        guard !items.isEmpty else {
            logService.add(
                text: "No stored updates to apply for sheet \(sheetId).",
                type: .info,
                context: String(describing: type(of: self))
            )
            return
        }

        try await MainActor.run {
            let context = modelContext

            // Fetch the cached sheet content
            let descriptor = FetchDescriptor<CachedSheetContent>(predicate: #Predicate { $0.id == sheetId })
            guard let cachedSheet = try? context.fetch(descriptor).first else {
                logService.add(
                    text: "CachedSheetContent not found for sheetId \(sheetId).",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                return
            }

            var appliedCount = 0

            for item in items {
                // Find the row
                guard let row = cachedSheet.rows.first(where: { $0.id == item.rowId }) else {
                    logService.add(
                        text: "Row not found (rowId: \(item.rowId)) for sheetId \(sheetId). Skipping.",
                        type: .warning,
                        context: String(describing: type(of: self))
                    )
                    continue
                }

                // Find the cell by columnId
                if let cell = row.cells.first(where: { $0.columnId == item.columnId }) {
                    cell.value = item.newValue
                    cell.displayValue = item.newValue
                    appliedCount += 1
                    logService.add(
                        text: "Updated cell — sheetId: \(sheetId), rowId: \(item.rowId), columnId: \(item.columnId) -> \"\(item.newValue)\"",
                        type: .debug,
                        context: String(describing: type(of: self))
                    )
                } else {
                    logService.add(
                        text: "Cell not found (columnId: \(item.columnId)) for rowId \(item.rowId) in sheetId \(sheetId). Skipping.",
                        type: .warning,
                        context: String(describing: type(of: self))
                    )
                }
            }

            do {
                try context.save()
                logService.add(
                    text: "Saved \(appliedCount) cell update(s) to SwiftData for sheetId \(sheetId).",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
            } catch {
                logService.add(
                    text: "Failed saving updated sheet content for sheetId \(sheetId): \(error)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
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
                    logService.add(
                        text: "No pending sheet content found in storage for sheetId \(sheetId). Nothing to remove.",
                        type: .info,
                        context: String(describing: type(of: self))
                    )
                    protectedSheetHasUpdatesToPublishStorageRepo.removeAll { $0.sheetId == sheetId }
                    return
                }

                toDelete.forEach { context.delete($0) }
                try context.save()
                
                ///TODO: Fix for some reason is throwing an error when saving
                logService.add(
                    text: "Removed \(toDelete.count) pending update record(s) from storage for sheetId \(sheetId).",
                    type: .debug,
                    context: String(describing: type(of: self))
                )
            } catch {
                logService.add(
                    text: "Failed to remove pending sheet content from storage for sheetId \(sheetId): \(error)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                throw error
            }

            // Also clear the in-memory mirror for this sheet (if any)
            protectedSheetHasUpdatesToPublishStorageRepo.removeAll { $0.sheetId == sheetId }
        }

        // Refresh published storage repo after mutation
        try? await getSheetListHasUpdatesToPublish()
    }
    
    private func storeSheetContent(sheetListResponse: SheetContent, discussions: [DiscussionDTO]) async throws {
        try await MainActor.run {
            let context = modelContext

            // Clear existing data for this sheet if needed
            let existing = try context.fetch(FetchDescriptor<CachedSheetContent>())
            existing
              .filter { (sheet: CachedSheetContent) in sheet.id == sheetListResponse.id }
              .forEach { context.delete($0) } //TODO: Fix, is throwing an error
            
            // Convert columns
            let cachedColumns: [CachedColumn] = (sheetListResponse.columns ?? []).map { (column: Column) in
                CachedColumn(
                    id: column.id,
                    index: column.index,
                    title: column.title,
                    type: column.type.rawValue,
                    primary: column.primary ?? false,
                    locked: column.locked ?? false,
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
                    CachedCell(
                        columnId: cell.columnId,
                        conditionalFormat: cell.conditionalFormat,
                        value: cell.value ?? "",
                        displayValue: cell.displayValue ?? "",
                        format: cell.format
                    )
                }
                return CachedRow(id: row.id, rowNumber: row.rowNumber, cells: cachedCells)
            }
            
            let cachedDiscussions: [CachedDiscussionDTO] = (discussions).map { CachedDiscussionDTO(from: $0) }

            // Create CachedSheetContent model
            let cachedSheet = CachedSheetContent(
                id: sheetListResponse.id,
                name: sheetListResponse.name,
                columns: cachedColumns,
                rows: cachedRows,
                discussions: cachedDiscussions
            )

            context.insert(cachedSheet)
            do {
                try context.save()
            } catch {
                logService.add(
                    text: "Error storing sheet content: \(sheetListResponse.name) in SwiftData. Error: \(error)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
                throw error
            }
        }
    }
}

// MARK: - HTTP Error Description Helper

extension SheetService {
    /// Helper to describe HTTPApiClientError (status, body, etc) for better logging.
    private func describeHTTPError(_ error: Error) -> String {
        guard let apiError = error as? HTTPApiClientError else {
            return "\(error)"
        }

        switch apiError {
        case .server(let statusCode, let body):
            if let body,
               let bodyString = String(data: body, encoding: .utf8) {
                return "status=\(statusCode) | body=\(bodyString)"
            } else {
                return "status=\(statusCode)"
            }
        case .transport(let underlying):
            return "transport error: \(underlying)"
        case .invalidResponse:
            return "invalid HTTP response"
        }
    }
}
