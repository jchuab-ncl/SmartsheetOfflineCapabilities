//
//  SheetHasUpdatesToPublish.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 06/08/25.
//
import SwiftData

import SwiftData

public struct CachedSheetHasUpdatesToPublishDTO: Identifiable, Hashable, Sendable {
    public var id: Int
    public var name: String
    public var newValue: String
    public var oldValue: String
    public var rowId: Int
    public var columnId: Int

    public init(
        id: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowId: Int,
        columnId: Int
    ) {
        self.id = id
        self.name = name
        self.newValue = newValue
        self.oldValue = oldValue
        self.rowId = rowId
        self.columnId = columnId
    }

    public init(from model: CachedSheetHasUpdatesToPublish) {
        self.id = model.id
        self.name = model.name
        self.newValue = model.newValue
        self.oldValue = model.oldValue
        self.rowId = model.rowId
        self.columnId = model.columnId
    }
}

@Model
public final class CachedSheetHasUpdatesToPublish {
    public var id: Int
    public var name: String
    public var newValue: String
    public var oldValue: String
    public var rowId: Int
    public var columnId: Int

    public init(
        id: Int,
        name: String,
        newValue: String,
        oldValue: String,
        rowId: Int,
        columnId: Int
    ) {
        self.id = id
        self.name = name
        self.newValue = newValue
        self.oldValue = oldValue
        self.rowId = rowId
        self.columnId = columnId
    }
}
