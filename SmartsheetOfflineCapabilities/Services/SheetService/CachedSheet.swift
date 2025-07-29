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
