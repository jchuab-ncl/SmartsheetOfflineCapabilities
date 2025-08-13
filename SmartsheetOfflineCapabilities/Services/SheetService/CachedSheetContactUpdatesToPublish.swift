//
//  CachedSheetContactUpdatesToPublish.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 13/08/25.
//

import Foundation
import SwiftData

public struct CachedSheetContactUpdatesToPublishDTO: Identifiable, Hashable, Sendable {
    public var id: Int = UUID().hashValue
    public var sheetId: Int
    public var rowId: Int
    public var columnId: Int
    public var name: String
    public var email: String

    public init(
        sheetId: Int,
        rowId: Int,
        columnId: Int,
        name: String,
        email: String,
    ) {
        self.sheetId = sheetId
        self.rowId = rowId
        self.columnId = columnId
        self.name = name
        self.email = email
    }

    public init(from model: CachedSheetContactUpdatesToPublish) {
        self.sheetId = model.sheetId
        self.rowId = model.rowId
        self.columnId = model.columnId
        self.name = model.name
        self.email = model.email
    }
}

@Model
public final class CachedSheetContactUpdatesToPublish {
    public var sheetId: Int
    public var rowId: Int
    public var columnId: Int
    public var name: String
    public var email: String

    public init(
        sheetId: Int,
        rowId: Int,
        columnId: Int,
        name: String,
        email: String
    ) {
        self.sheetId = sheetId
        self.rowId = rowId
        self.columnId = columnId
        self.name = name
        self.email = email
    }
}
