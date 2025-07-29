//
//  CachedSheetDetailResponse.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 25/07/25.
//

import SwiftData

// MARK: Model

@Model
public final class CachedSheetContent {
    @Attribute(.unique) public var id: Int
    public var name: String
    @Relationship public var columns: [CachedColumn]
    @Relationship public var rows: [CachedRow]

    public init(id: Int, name: String, columns: [CachedColumn], rows: [CachedRow]) {
        self.id = id
        self.name = name
        self.columns = columns
        self.rows = rows
    }
}

@Model
public final class CachedContact {
    public var email: String
    public var name: String
    @Relationship(inverse: \CachedColumn.contactOptions) public var column: CachedColumn?

    public init(email: String, name: String) {
        self.email = email
        self.name = name
    }

    public var asDTO: ContactDTO {
        return ContactDTO(email: email, name: name)
    }
}

@Model
public final class CachedColumn {
    @Attribute(.unique) public var id: Int
    public var index: Int
    public var title: String
    public var type: String
    public var systemColumnType: String?
    public var hidden: Bool?
    public var width: Int
    public var options: [String]
    @Relationship public var contactOptions: [CachedContact]

    public init(
        id: Int,
        index: Int,
        title: String,
        type: String,
        systemColumnType: String,
        hidden: Bool,
        width: Int = 0,
        options: [String],
        contactOptions: [CachedContact] = []
    ) {
        self.id = id
        self.index = index
        self.title = title
        self.type = type
        self.systemColumnType = systemColumnType
        self.hidden = hidden
        self.width = width
        self.options = options
        self.contactOptions = contactOptions
    }
}

@Model
public final class CachedCell {
    public var columnId: Int
    public var value: String?
    public var displayValue: String?
    @Relationship(inverse: \CachedRow.cells) public var row: CachedRow?

    public init(columnId: Int, value: String?, displayValue: String?) {
        self.columnId = columnId
        self.value = value
        self.displayValue = displayValue
    }
}

@Model
public final class CachedRow {
    @Attribute(.unique) public var id: Int
    public var rowNumber: Int
    @Relationship public var cells: [CachedCell]

    public init(id: Int, rowNumber: Int, cells: [CachedCell]) {
        self.id = id
        self.rowNumber = rowNumber
        self.cells = cells
    }
}

extension Array where Element == CachedContact {
    public var asDTOs: [ContactDTO] {
        return self.map(\.asDTO)
    }
}

// MARK: DTO

public struct SheetContentDTO: Identifiable, Hashable, Sendable {
    public var id: Int
    public var name: String
    public var columns: [ColumnDTO]
    public var rows: [RowDTO]

    public init(id: Int, name: String, columns: [ColumnDTO], rows: [RowDTO]) {
        self.id = id
        self.name = name
        self.columns = columns
        self.rows = rows
    }
}

public struct ContactDTO: Hashable, Sendable {
    public var email: String
    public var name: String

    public init(email: String, name: String) {
        self.email = email
        self.name = name
    }
}

public struct ColumnDTO: Identifiable, Hashable, Sendable {
    public var id: Int
    public var index: Int
    public var title: String
    public var type: ColumnType
    public var systemColumnType: String
    public var hidden: Bool
    public var width: Int
    public var options: [String]
    public var contactOptions: [ContactDTO]

    public init(
        id: Int,
        index: Int,
        title: String,
        type: ColumnType,
        systemColumnType: String,
        hidden: Bool,
        width: Int,
        options: [String],
        contactOptions: [ContactDTO] = []
    ) {
        self.id = id
        self.index = index
        self.title = title
        self.type = type
        self.systemColumnType = systemColumnType
        self.hidden = hidden
        self.width = width
        self.options = options
        self.contactOptions = contactOptions
    }
}

public struct RowDTO: Identifiable, Hashable, Sendable {
    public var id: Int
    public let rowNumber: Int
    public var cells: [CellDTO]

    public init(id: Int, rowNumber: Int, cells: [CellDTO]) {
        self.id = id
        self.rowNumber = rowNumber
        self.cells = cells
    }
}

public struct CellDTO: Hashable, Sendable {
    public var columnId: Int
    public var value: String?
    public var displayValue: String?

    public init(columnId: Int, value: String?, displayValue: String?) {
        self.columnId = columnId
        self.value = value
        self.displayValue = displayValue
    }
}
