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
    public var sheetId: Int
    public var sheetName: String
    public var newValue: String
    public var oldValue: String
    public var rowId: Int
    public var columnId: Int

    public init(
        sheetId: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowId: Int,
        columnId: Int
    ) {
        self.sheetId = sheetId
        self.sheetName = name
        self.newValue = newValue
        self.oldValue = oldValue
        self.rowId = rowId
        self.columnId = columnId
    }

    public init(from model: CachedSheetHasUpdatesToPublish) {
        self.sheetId = model.sheetId
        self.sheetName = model.name
        self.newValue = model.newValue
        self.oldValue = model.oldValue
        self.rowId = model.rowId
        self.columnId = model.columnId
    }
}

@Model
public final class CachedSheetHasUpdatesToPublish {
    public var sheetId: Int
    public var name: String
    public var newValue: String
    public var oldValue: String
    public var rowId: Int
    public var columnId: Int

    public init(
        sheetId: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowId: Int,
        columnId: Int
    ) {
        self.sheetId = sheetId
        self.name = name
        self.newValue = newValue
        self.oldValue = oldValue
        self.rowId = rowId
        self.columnId = columnId
    }
}
