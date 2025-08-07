//
//  CachedSheet.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 25/07/25.
//

import SwiftData

// MARK: DTO

public struct CachedSheetDTO: Sendable, Identifiable, Hashable {
    public var id: Int
    public var modifiedAt: String
    public var name: String
}

// MARK: Model

@Model
final public class CachedSheet {
    @Attribute(.unique) public var id: Int
    public var modifiedAt: String
    public var name: String

    /// Initializes a new `CachedSheet` model to be stored using SwiftData.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the sheet (matches the Smartsheet API sheet ID).
    ///   - modifiedAt: A string representing the last modification timestamp of the sheet (as provided by the API).
    ///   - name: The name of the sheet.
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
