//
//  SheetHasUpdatesToPublish.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 06/08/25.
//

import Foundation
import SwiftData

public struct CachedSheetHasUpdatesToPublishDTO: Identifiable, Hashable, Sendable {
    public var id: Int = UUID().hashValue
    public var columnType: String
    public var sheetId: Int
    public var sheetName: String
    public var newValue: String
    public var oldValue: String
    public var rowNumber: Int
    public var rowId: Int
    public var columnName: String
    public var columnId: Int
    public var contacts: [CachedSheetContactUpdatesToPublishDTO]

    public init(
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
    ) {
        self.columnType = columnType
        self.sheetId = sheetId
        self.sheetName = name
        self.newValue = newValue
        self.oldValue = oldValue
        self.rowNumber = rowNumber
        self.rowId = rowId
        self.columnName = columnName
        self.columnId = columnId
        self.contacts = contacts
    }

    public init(from model: CachedSheetHasUpdatesToPublish, contacts: [CachedSheetContactUpdatesToPublishDTO]) {
        self.columnType = model.columnType
        self.sheetId = model.sheetId
        self.sheetName = model.name
        self.newValue = model.newValue
        self.oldValue = model.oldValue
        self.rowNumber = model.rowNumber
        self.rowId = model.rowId
        self.columnName = model.columnName
        self.columnId = model.columnId
        
        //TODO:
        self.contacts = contacts
    }
}

@Model
public final class CachedSheetHasUpdatesToPublish {
    public var columnType: String
    public var sheetId: Int
    public var name: String
    public var newValue: String
    public var oldValue: String
    public var rowNumber: Int
    public var rowId: Int
    public var columnName: String
    public var columnId: Int

    public init(
        columnType: String,
        sheetId: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowNumber: Int,
        rowId: Int,
        columnName: String,
        columnId: Int
    ) {
        self.columnType = columnType
        self.sheetId = sheetId
        self.name = name
        self.newValue = newValue
        self.oldValue = oldValue
        self.rowNumber = rowNumber
        self.rowId = rowId
        self.columnName = columnName
        self.columnId = columnId
    }
}
