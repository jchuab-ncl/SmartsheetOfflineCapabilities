//
//  SheetDetailResponse.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

public struct SheetDetailResponse: Codable, Equatable {
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

public struct Column: Codable, Equatable {
    public let id: Int
    public let index: Int
    public let title: String
    public let type: String
    public let primary: Bool?
    public let hidden: Bool?
    public let locked: Bool?
    public let lockedForUser: Bool?
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
    public let discussionId: Int
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
    public let rowNumber: Int?
    public let modifiedAt: String?
    public let createdAt: String?
    public let locked: Bool?
    public let lockedForUser: Bool?
    public let expanded: Bool?
    public let filteredOut: Bool?
    public let format: String?
    public let cells: [SheetCell]?
}

public struct SheetCell: Codable, Equatable {
    public let columnId: Int
    public let value: String?
    public let displayValue: String?
    public let format: String?
    public let formula: String?

    enum CodingKeys: String, CodingKey {
        case columnId
        case value
        case displayValue
        case format
        case formula
    }

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
    public let accessLevel: String
    public let permalink: String?
}
