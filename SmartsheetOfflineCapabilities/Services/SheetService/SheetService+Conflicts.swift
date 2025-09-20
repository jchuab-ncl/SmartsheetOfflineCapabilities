//
//  SheetService+Conflicts.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/09/25.
//

import Foundation
import SwiftData

/// Represents a conflict between local and server cell updates.
public struct Conflict {
    public let sheetId: Int
    public let rowId: Int
    public let columnId: Int
    public let columnType: ColumnType
    public let serverValue: String
    public let localValue: String
    public let cachedSheetHasUpdatesToPublishDTO: CachedSheetHasUpdatesToPublishDTO?
    public var isResolved: Bool
    
    public static var empty: Conflict = .init(
        sheetId: 0,
        rowId: 0,
        columnId: 0,
        columnType: .textNumber,
        serverValue: "",
        localValue: "",
        cachedSheetHasUpdatesToPublishDTO: nil,
        isResolved: false
    )
}

/// Holds the result of a conflict check: conflicts and mergeable updates.
//public struct ConflictResult {
//    public var conflicts: [Conflict]
//    public let mergeable: [CachedSheetHasUpdatesToPublishDTO]
//    
//    public static let empty: ConflictResult = .init(conflicts: [], mergeable: [])
//    
//    init(conflicts: [Conflict], mergeable: [CachedSheetHasUpdatesToPublishDTO]) {
//        self.conflicts = conflicts
//        self.mergeable = mergeable
//    }
//}

extension SheetService {
    /// Checks for conflicts between local cached updates and the latest server content for a sheet.
    /// - Parameter sheetId: The sheet to check.
    /// - Returns: ConflictResult containing conflicts and mergeable updates.
    public func checkForConflicts(sheetId: Int) async throws {
        // 1. Fetch latest server content
        let serverContent = try await getSheetContentOnline(sheetId: sheetId, storeContent: true)

        // 2. Build a map of latest server values: [rowId: [columnId: value]]
        var serverValues: [Int: [Int: String?]] = [:]
        for row in serverContent.rows {
            var cellMap: [Int: String?] = [:]
            for cell in row.cells {
                cellMap[cell.columnId] = cell.value
            }
            serverValues[row.id] = cellMap
        }

        // 3. Get local updates (pending updates to publish) for this sheet
        let localUpdates = protectedSheetHasUpdatesToPublishStorageRepo.filter { $0.sheetId == sheetId }

        var conflicts: [Conflict] = []
        var mergeable: [CachedSheetHasUpdatesToPublishDTO] = []

        // 4. For each local update, compare the original value to the latest server value
        for update in localUpdates {
            let rowId = update.rowId
            let columnId = update.columnId
            let serverValue = serverValues[rowId]?[columnId] ?? nil
            // If the server value is different from original, and also different from the local newValue, it's a conflict.
            // If the server value == original, then it's mergeable (not changed remotely).
            if let server = serverValue, update.oldValue != server {
                // The cell was changed remotely since we last cached it
                if server != update.newValue {
                    
                    // Check if the conflict was already solved:
                    let solvedConflict: Conflict? = protectedConflictResultMemoryRepo.first(where: {
                        $0.sheetId == sheetId && $0.rowId == rowId && $0.columnId == columnId && $0.isResolved
                    })
                    
                    if solvedConflict == nil {
                        // True conflict: both local and remote have changed
                        conflicts.append(
                            Conflict(
                                sheetId: sheetId,
                                rowId: rowId,
                                columnId: columnId,
                                columnType: ColumnType(rawValue: update.columnType) ?? .textNumber,
                                serverValue: server,
                                localValue: update.newValue,
                                cachedSheetHasUpdatesToPublishDTO: update,
                                isResolved: false
                            ))
                    }
                } else {
                    // Both changed to same value, treat as mergeable
                    mergeable.append(update)
                }
//            }
//            else if let serverValue {
//                // Cell was added remotely; treat as conflict if local also has a value
//                if update.newValue != serverValue {
//                    conflicts.append(
//                        Conflict(
//                            sheetId: sheetId,
//                            rowId: rowId,
//                            columnId: columnId,
//                            serverValue: serverValue,
//                            localValue: update.newValue,
//                            cachedSheetHasUpdatesToPublishDTO: update
//                        ))
//                } else {
//                    mergeable.append(update)
//                }
            } else {
                // No remote change, safe to merge
                mergeable.append(update)
            }
        }

        protectedConflictResultMemoryRepo = conflicts
    }
    
    public func addSolvedConflict(conflict: Conflict) {
        protectedConflictResultMemoryRepo.removeAll(where: { $0.rowId == conflict.rowId && $0.columnId == $0.columnId && $0.sheetId == $0.sheetId })
        /// Appending conflict that has isResolved == true
        protectedConflictResultMemoryRepo.append(conflict)
    }
}
