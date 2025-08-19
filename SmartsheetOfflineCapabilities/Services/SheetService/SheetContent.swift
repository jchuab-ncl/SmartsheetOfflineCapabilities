//
//  SheetContent.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

public struct SheetContent: Codable, Equatable {
    public let id: Int
    public let fromId: Int?
    public let ownerId: Int?
    public let accessLevel: String
    public let attachments: [Attachment]?
    public let cellImageUploadEnabled: Bool?
    public let columns: [Column]?
    public let createdAt: String?
    public let crossSheetReferences: [CrossSheetReference]?
    public let dependenciesEnabled: Bool?
    public let discussions: [Discussion]?
    public let effectiveAttachmentOptions: [String]?
    public let favorite: Bool?
    public let ganttEnabled: Bool?
    public let hasSummaryFields: Bool?
    public let isMultiPicklistEnabled: Bool?
    public let modifiedAt: String?
    public let name: String
    public let owner: String?
    public let permalink: String?
    public let projectSettings: ProjectSettings?
    public let readOnly: Bool?
    public let resourceManagementEnabled: Bool?
    public let resourceManagementType: String?
    public let rows: [Row]?
    public let showParentRowsForFilters: Bool?
    public let source: SheetSource?
    public let summary: SummarySection?
    public let totalRowCount: Int?
    public let userPermissions: UserPermissions?
    public let userSettings: UserSettings?
    public let version: Int?
    public let workspace: Workspace?
}

public struct Attachment: Codable, Equatable {
    public let id: Int
    public let parentId: Int
    public let attachmentType: String
    public let attachmentSubType: String
    public let mimeType: String
    public let parentType: String
    public let createdAt: String
    public let createdBy: CreatedBy?
    public let name: String
    public let sizeInKb: Int
    public let url: String
    public let urlExpiresInMillis: Int
}

public struct CreatedBy: Codable, Equatable {
    public let email: String?
    public let name: String?
}

public enum ColumnType: String, Codable, Sendable {
    case abstractDateTime = "ABSTRACT_DATETIME"
    case checkbox = "CHECKBOX"
    case contactList = "CONTACT_LIST"
    case date = "DATE"
    case dateTime = "DATETIME"
    case duration = "DURATION"
    case multiContactList = "MULTI_CONTACT_LIST"
    case multiPicklist = "MULTI_PICKLIST"
    case picklist = "PICKLIST"
    case predecessor = "PREDECESSOR"
    case textNumber = "TEXT_NUMBER"
    
    public init?(rawValue: String) {
        switch rawValue {
        case "ABSTRACT_DATETIME": self = .abstractDateTime
        case "CHECKBOX": self = .checkbox
        case "CONTACT_LIST": self = .contactList
        case "DATE": self = .date
        case "DATETIME": self = .dateTime
        case "DURATION": self = .duration
        case "MULTI_CONTACT_LIST": self = .multiContactList
        case "MULTI_PICKLIST": self = .multiPicklist
        case "PICKLIST": self = .picklist
        case "PREDECESSOR": self = .predecessor
        case "TEXT_NUMBER": self = .textNumber
        default:
            return nil
        }
    }
}

public struct Contact: Codable, Equatable {
    public let email: String
    public let name: String
    
    public var asDTO: ContactDTO {
        return ContactDTO(email: self.email, name: self.name)
    }
    
    public var asCached: CachedContact {
        return CachedContact(email: self.email, name: self.name)
    }
}

extension Array where Element == Contact {
    public var asDTOs: [ContactDTO] {
        return self.map(\.asDTO)
    }
    
    public var asCached: [CachedContact] {
        return self.map(\.asCached)
    }
}

//public struct Option: Codable, Equatable {
//    public let value: String
//
//    public var asDTO: OptionDTO {
//        return OptionDTO(value: self.value)
//    }
//
//    public var asCached: CachedOption {
//        return CachedOption(value: self.value)
//    }
//}
//
//extension Array where Element == Option {
//    public var asDTOs: [OptionDTO] {
//        return self.map(\.asDTO)
//    }
//
//    public var asCached: [CachedOption] {
//        return self.map(\.asCached)
//    }
//}

public struct Column: Codable, Equatable {
    public let id: Int
    public let index: Int
    public let title: String
    public let type: ColumnType
    public let primary: Bool?
    public let hidden: Bool?
    public let locked: Bool?
    public let lockedForUser: Bool?
    public let options: [String]?
    public let width: Int
    public let systemColumnType: String?
    public let contactOptions: [Contact]?
    
    public enum CodingKeys: CodingKey {
        case id
        case index
        case title
        case type
        case primary
        case hidden
        case locked
        case lockedForUser
        case options
        case width
        case systemColumnType
        case contactOptions
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.index = try container.decode(Int.self, forKey: .index)
        self.title = try container.decode(String.self, forKey: .title)
         
        let value = try container.decode(String.self, forKey: .type)
        if let columnType = ColumnType.init(rawValue: value) {
            self.type = columnType
        } else {
            self.type = .textNumber
        }
        
        self.primary = try container.decodeIfPresent(Bool.self, forKey: .primary)
        self.hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        self.locked = try container.decodeIfPresent(Bool.self, forKey: .locked)
        self.lockedForUser = try container.decodeIfPresent(Bool.self, forKey: .lockedForUser)
        self.options = try container.decodeIfPresent([String].self, forKey: .options)
        self.width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 0
        self.systemColumnType = try container.decodeIfPresent(String.self, forKey: .systemColumnType)
        self.contactOptions = try container.decodeIfPresent([Contact].self, forKey: .contactOptions)
    }
}

public struct CrossSheetReference: Codable, Equatable {
    public let id: Int
    public let name: String
    public let sourceSheetId: Int
    public let status: String
    public let startColumnId: Int
    public let startRowId: Int
    public let endColumnId: Int
    public let endRowId: Int
}

public struct Discussion: Codable, Equatable {
    public let id: Int
    public let accessLevel: String
    public let comments: [Comment]?
    public let commentAttachments: [Attachment]?
    public let commentCount: Int?
    public let createdBy: CreatedBy?
    public let lastCommentedAt: String?
    public let lastCommentedUser: CreatedBy?
    public let parentId: Int?
    public let parentType: String?
    public let readOnly: Bool?
    public let title: String?
}

public struct Comment: Codable, Equatable {
    public let id: Int
    public let discussionId: Int?
    public let text: String
    public let createdAt: String
    public let modifiedAt: String
    public let createdBy: CreatedBy?
    public let attachments: [Attachment]?
}

public struct Row: Codable, Equatable {
    public let id: Int
    public let sheetId: Int?
    public let accessLevel: String?
    public let rowNumber: Int
    public let modifiedAt: String?
    public let createdAt: String?
    public let locked: Bool?
    public let lockedForUser: Bool?
    public let expanded: Bool?
    public let filteredOut: Bool?
    public let format: String?
    public let cells: [SheetCell]?
}

/// Represents a single cell in a Smartsheet row.
public struct SheetCell: Codable, Equatable {
    /// The unique identifier of the column this cell belongs to.
    public let columnId: Int

    /// The raw value of the cell, decoded as a String. It can be originally a String or an Int.
    public var value: String?

    /// The formatted value as displayed in the Smartsheet UI.
    public var displayValue: String?

    /// The format applied to the cell, if any.
    public let format: String?

    /// The formula expression for the cell, if present.
    public let formula: String?

    /// Coding keys used for decoding from JSON.
    enum CodingKeys: String, CodingKey {
        case columnId, value, displayValue, format, formula
    }

    /// A static placeholder instance of an empty SheetCell.
    public static var empty = SheetCell(columnId: 0, value: nil, displayValue: nil, format: nil, formula: nil)

    /// Creates a new instance of `SheetCell` with the provided values.
    /// - Parameters:
    ///   - columnId: The identifier of the column this cell belongs to.
    ///   - value: The raw value of the cell, stored as a `String`. Can be derived from a `String` or an `Int`.
    ///   - displayValue: The formatted display value shown in the Smartsheet UI.
    ///   - format: A format string applied to the cell, if any.
    ///   - formula: The formula string used to calculate the cell’s value, if applicable.
    public init(columnId: Int, value: String?, displayValue: String?, format: String?, formula: String?) {
        self.columnId = columnId
        self.value = value
        self.displayValue = displayValue
        self.format = format
        self.formula = formula
    }

    /// Decodes a `SheetCell` from a `Decoder`, handling `value` as either a `String` or an `Int`.
    /// This allows compatibility with Smartsheet's variable JSON structure for cell values.
    /// - Parameter decoder: The decoder instance used to decode this struct.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        columnId = try container.decode(Int.self, forKey: .columnId)
        displayValue = try container.decodeIfPresent(String.self, forKey: .displayValue)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        formula = try container.decodeIfPresent(String.self, forKey: .formula)

        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .value) {
            value = String(intValue)
        } else {
            value = nil
        }
    }
}

public struct SummarySection: Codable, Equatable {
    public let fields: [SummaryField]?
}

public struct SummaryField: Codable, Equatable {
    public let id: Int
    public let title: String?
    public let type: String?
    public let displayValue: String?
}

public struct ProjectSettings: Codable, Equatable {
    public let lengthOfDay: Int
    public let nonWorkingDays: [String]
    public let workingDays: [String]
}

public struct UserPermissions: Codable, Equatable {
    public let summaryPermissions: String?
}

public struct UserSettings: Codable, Equatable {
    public let criticalPathEnabled: Bool?
    public let displaySummaryTasks: Bool?
}

public struct Workspace: Codable, Equatable {
    public let id: Int
    public let name: String
    public let accessLevel: String?
    public let permalink: String?
}

// MARK: Mock

public struct SheetContentMock {
    public static func makeMock() -> SheetContent {
        return SheetContent(
            id: 1,
            fromId: nil,
            ownerId: nil,
            accessLevel: "EDITOR",
            attachments: [],
            cellImageUploadEnabled: true,
            columns: [],
            createdAt: "2025-07-10T12:00:00Z",
            crossSheetReferences: [],
            dependenciesEnabled: false,
            discussions: [],
            effectiveAttachmentOptions: [],
            favorite: false,
            ganttEnabled: false,
            hasSummaryFields: false,
            isMultiPicklistEnabled: false,
            modifiedAt: "2025-07-11T12:00:00Z",
            name: "Mocked Sheet",
            owner: "Mock Owner",
            permalink: "https://example.com/sheet/1",
            projectSettings: nil,
            readOnly: false,
            resourceManagementEnabled: false,
            resourceManagementType: nil,
            rows: [],
            showParentRowsForFilters: false,
            source: SheetSource(id: 123, type: "template"),
            summary: nil,
            totalRowCount: 0,
            userPermissions: nil,
            userSettings: nil,
            version: 1,
            workspace: nil
        )
    }
}
