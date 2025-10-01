//
//  CachedSheetContent.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 25/07/25.
//

import Foundation
import SwiftData

// MARK: Model

@Model
public final class CachedSheetContent {
    @Attribute(.unique) public var id: Int
    public var name: String
    @Relationship(deleteRule: .cascade) public var columns: [CachedColumn]
    @Relationship(deleteRule: .cascade) public var rows: [CachedRow]
    @Relationship(deleteRule: .cascade) public var discussions: [CachedDiscussionDTO]

    public init(
        id: Int,
        name: String,
        columns: [CachedColumn],
        rows: [CachedRow],
        discussions: [CachedDiscussionDTO]
    ) {
        self.id = id
        self.name = name
        self.columns = columns
        self.rows = rows
        self.discussions = discussions
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
public final class CachedOption {
    public var value: String
    @Relationship(inverse: \CachedColumn.options) public var column: CachedColumn?

    public init(value: String) {
        self.value = value
    }
}

@Model
public final class CachedColumn {
    public var format: String?
    @Attribute(.unique) public var id: Int
    public var index: Int
    public var title: String
    public var type: String
    public var primary: Bool?
    public var systemColumnType: String?
    public var hidden: Bool?
    public var width: Int
    @Relationship(deleteRule: .cascade) public var options: [CachedOption]
    @Relationship(deleteRule: .cascade) public var contactOptions: [CachedContact]

    public init(
        id: Int,
        index: Int,
        title: String,
        type: String = "",
        primary: Bool?,
        systemColumnType: String,
        hidden: Bool,
        width: Int = 0,
        options: [String],
        contactOptions: [CachedContact] = [],
        format: String? = nil
    ) {
        self.format = format
        self.id = id
        self.index = index
        self.title = title
        self.type = type
        self.primary = primary
        self.systemColumnType = systemColumnType
        self.hidden = hidden
        self.width = width
        self.options = []
        self.contactOptions = []

        // Fix inverse for options
        self.options = options.map { value in
            let option = CachedOption(value: value)
            option.column = self
            return option
        }

        // Fix inverse for contactOptions
        self.contactOptions = contactOptions.map {
            $0.column = self
            return $0
        }
    }
}

@Model
public final class CachedCell {
    public var columnId: Int
    public var conditionalFormat: String?
    public var value: String?
    public var displayValue: String?
    public var format: String?
    @Relationship(inverse: \CachedRow.cells) public var row: CachedRow?

    public init(columnId: Int, conditionalFormat: String?, value: String?, displayValue: String?, format: String?) {
        self.columnId = columnId
        self.conditionalFormat = conditionalFormat
        self.value = value
        self.displayValue = displayValue
    }
}

@Model
public final class CachedRow {
    @Attribute(.unique) public var id: Int
    public var rowNumber: Int
    @Relationship(deleteRule: .cascade) public var cells: [CachedCell]

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
    public var discussions: [DiscussionDTO] = []

    public init(id: Int, name: String, columns: [ColumnDTO], rows: [RowDTO], discussions: [DiscussionDTO] ) {
        self.id = id
        self.name = name
        self.columns = columns
        self.rows = rows
        self.discussions = discussions
    }
    
    static var empty: SheetContentDTO {
        return .init(id: 0, name: "", columns: [], rows: [], discussions: [])
    }
    
    public func discussionsForRow(_ rowId: Int) -> [DiscussionDTO] {
        return discussions.filter( {
            $0.parentType == "ROW" && $0.parentId == rowId
        })
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
    public var format: String?
    public var id: Int
    public var index: Int
    public var title: String
    public var type: ColumnType
    public let primary: Bool?
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
        primary: Bool?,
        systemColumnType: String,
        hidden: Bool,
        width: Int,
        options: [String],
        contactOptions: [ContactDTO] = [],
        format: String? = nil
    ) {
        self.format = format
        self.id = id
        self.index = index
        self.title = title
        self.type = type
        self.primary = primary
        self.systemColumnType = systemColumnType
        self.hidden = hidden
        self.width = width
        self.options = options
        self.contactOptions = contactOptions
    }
    
    public init(from value: CachedColumn) {
        self.format = value.format
        self.id = value.id
        self.index = value.index
        self.title = value.title
        self.type = .init(rawValue: value.type) ?? .textNumber
        self.primary = value.primary
        self.systemColumnType = value.systemColumnType ?? ""
        self.hidden = value.hidden ?? false
        self.width = value.width
        self.options = value.options.map { $0.value }
        self.contactOptions = value.contactOptions.asDTOs
    }
}

public struct RowDTO: Identifiable, Hashable, Sendable {
    public var id: Int
    public var dateTime: Date?
    public let rowNumber: Int
    public var cells: [CellDTO]

    public init(id: Int, dateTime: Date?, rowNumber: Int, cells: [CellDTO]) {
        self.id = id
        self.dateTime = dateTime
        self.rowNumber = rowNumber
        self.cells = cells
    }
    
    //TODO: The row's order when pushing to the server are not correct.
    
    public init(id: Int, rowNumber: Int, cells: [CellDTO]) {
        self.id = id
        self.rowNumber = rowNumber
        self.cells = cells
    }
}

public struct CellDTO: Hashable, Sendable {
    public var columnId: Int
    public let conditionalFormat: String?
    public var value: String?
    public var displayValue: String?
    public var format: String?

    public init(
        columnId: Int,
        conditionalFormat: String?,
        value: String?,
        displayValue: String?,
        format: String?
    ) {
        self.columnId = columnId
        self.conditionalFormat = conditionalFormat
        self.value = value
        self.displayValue = displayValue
        self.format = format
    }
}
