//
//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 29/08/25.
//

import Foundation
import SwiftData

public enum CachedSheetDiscussionToPublishDTOType: String, Codable, Sendable {
    case row = "ROW"
    case sheet = "SHEET"
}

public struct CachedSheetDiscussionToPublishDTO: Identifiable, Hashable, Sendable {
    public var id: Int = UUID().hashValue
    public var dateTime: Date
    public var parentId: Int
    public var parentType: CachedSheetDiscussionToPublishDTOType
    public var comment: CachedSheetDiscussionTextDTO
    public var firstNameUser: String
    public var lastNameUser: String
    
    public var userName: String {
        "\(firstNameUser) \(lastNameUser)"
    }
    
    init(
        dateTime: Date,
        parentId: Int,
        parentType: CachedSheetDiscussionToPublishDTOType,
        comment: CachedSheetDiscussionTextDTO,
        firstNameUser: String,
        lastNameUser: String
    ) {
        self.dateTime = dateTime
        self.parentId = parentId
        self.parentType = parentType
        self.comment = comment
        self.firstNameUser = firstNameUser
        self.lastNameUser = lastNameUser
    }
    
    init(from value: CachedSheetDiscussionsToPublish) {
        self.dateTime = value.dateTime
        self.parentId = value.parentId
        self.parentId = value.parentId
        self.parentType = .init(rawValue: value.parentType) ?? .sheet
        self.comment = .init(text: value.comment?.text ?? "")
        self.firstNameUser = value.firstNameUser
        self.lastNameUser = value.lastNameUser
    }
}

public struct CachedSheetDiscussionTextDTO: Identifiable, Hashable, Sendable {
    public var id: Int = UUID().hashValue
    public var text: String
}

@Model
public final class CachedSheetDiscussionsToPublish {
    public var dateTime: Date
    public var parentId: Int
    public var parentType: String
    public var firstNameUser: String
    public var lastNameUser: String
    @Relationship(deleteRule: .cascade) public var comment: CachedSheetDiscussionText?

    init(
        dateTime: Date,
        parentId: Int,
        parentType: String,
        firstNameUser: String,
        lastNameUser: String,
        comment: CachedSheetDiscussionText? = nil
    ) {
        self.dateTime = dateTime
        self.parentId = parentId
        self.parentType = parentType
        self.firstNameUser = firstNameUser
        self.lastNameUser = lastNameUser
        self.comment = comment
    }
}

@Model
public final class CachedSheetDiscussionText {
    public var text: String
    @Relationship(inverse: \CachedSheetDiscussionsToPublish.comment) public var discussion: CachedSheetDiscussionsToPublish?   // inverse relationship

    init(text: String) {
        self.text = text
    }
}
