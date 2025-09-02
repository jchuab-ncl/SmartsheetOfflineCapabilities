//
//  CachedDiscussionDTO.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 19/08/25.
//

import Foundation
import SwiftData

// MARK: - SwiftData Models (Caching)

@Model
public final class CachedDiscussionDTO {
    @Attribute(.unique) public var id: Int
    public var accessLevel: String?
    public var title: String?
    public var commentCount: Int
    public var parentId: Int?
    public var parentType: String?
    public var readOnly: Bool
    public var lastCommentedAt: String

    // Flattened creator fields (simplify SwiftData graph)
    public var createdByName: String?
    public var createdByEmail: String?
    public var lastCommentedUserName: String?
    public var lastCommentedUserEmail: String?

    @Relationship(deleteRule: .cascade) public var comments: [CachedCommentDTO]
    @Relationship(deleteRule: .cascade) public var commentAttachments: [CachedAttachmentDTO]

    public init(
        id: Int,
        accessLevel: String?,
        title: String?,
        commentCount: Int,
        parentId: Int?,
        parentType: String?,
        readOnly: Bool,
        lastCommentedAt: String,
        createdByName: String?,
        createdByEmail: String?,
        lastCommentedUserName: String?,
        lastCommentedUserEmail: String?,
        comments: [CachedCommentDTO] = [],
        commentAttachments: [CachedAttachmentDTO] = []
    ) {
        self.id = id
        self.accessLevel = accessLevel
        self.title = title
        self.commentCount = commentCount
        self.parentId = parentId
        self.parentType = parentType
        self.readOnly = readOnly
        self.lastCommentedAt = lastCommentedAt
        self.createdByName = createdByName
        self.createdByEmail = createdByEmail
        self.lastCommentedUserName = lastCommentedUserName
        self.lastCommentedUserEmail = lastCommentedUserEmail
        self.comments = comments
        self.commentAttachments = commentAttachments
    }
        
    public convenience init(from discussion: DiscussionDTO) {
        let cachedComments: [CachedCommentDTO] = (discussion.comments ?? []).map { CachedCommentDTO(from: $0) }
        let cachedTopLevelAttachments: [CachedAttachmentDTO] = (discussion.commentAttachments ?? []).map { CachedAttachmentDTO(from: $0) }
        self.init(
            id: discussion.id,
            accessLevel: discussion.accessLevel,
            title: discussion.title,
            commentCount: discussion.commentCount ?? 0,
            parentId: discussion.parentId,
            parentType: discussion.parentType,
            readOnly: discussion.readOnly ?? false,
            lastCommentedAt: discussion.lastCommentedAt,
            createdByName: discussion.createdBy?.name,
            createdByEmail: discussion.createdBy?.email,
            lastCommentedUserName: discussion.lastCommentedUser?.name,
            lastCommentedUserEmail: discussion.lastCommentedUser?.email,
            comments: cachedComments,
            commentAttachments: cachedTopLevelAttachments
        )
    }
}

@Model
public final class CachedCommentDTO {
    @Attribute(.unique) public var id: Int
    public var discussionId: Int?
    public var text: String?
    public var createdAt: String?
    public var modifiedAt: String?

    // Flattened creator
    public var createdByName: String?
    public var createdByEmail: String?

    @Relationship(deleteRule: .cascade) public var attachments: [CachedAttachmentDTO]

    public init(
        id: Int,
        discussionId: Int?,
        text: String?,
//        createdAt: String?,
        modifiedAt: String?,
        createdByName: String?,
        createdByEmail: String?,
        attachments: [CachedAttachmentDTO] = []
    ) {
        self.id = id
        self.discussionId = discussionId
        self.text = text
//        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.createdByName = createdByName
        self.createdByEmail = createdByEmail
        self.attachments = attachments
    }
    
    convenience init(from comment: CommentDTO) {
        let cachedAttachments: [CachedAttachmentDTO] = (comment.attachments ?? []).map { CachedAttachmentDTO(from: $0) }
        self.init(
            id: comment.id,
            discussionId: comment.discussionId,
            text: comment.text,
//            createdAt: comment.createdAt,
            modifiedAt: comment.modifiedAt,
            createdByName: comment.createdBy?.name,
            createdByEmail: comment.createdBy?.email,
            attachments: cachedAttachments
        )
    }
}

@Model
public final class CachedAttachmentDTO {
    @Attribute(.unique) public var id: Int
    public var parentId: Int?
    public var attachmentType: String?
    public var attachmentSubType: String?
    public var mimeType: String?
    public var parentType: String?
    public var createdAt: String?
    public var createdByName: String?
    public var createdByEmail: String?
    public var name: String?
    public var sizeInKb: Int?
    public var url: String?
    public var urlExpiresInMillis: Int?

    public init(
        id: Int,
        parentId: Int?,
        attachmentType: String?,
        attachmentSubType: String?,
        mimeType: String?,
        parentType: String?,
//        createdAt: String?,
        createdByName: String?,
        createdByEmail: String?,
        name: String?,
        sizeInKb: Int?,
        url: String?,
        urlExpiresInMillis: Int?
    ) {
        self.id = id
        self.parentId = parentId
        self.attachmentType = attachmentType
        self.attachmentSubType = attachmentSubType
        self.mimeType = mimeType
        self.parentType = parentType
//        self.createdAt = createdAt
        self.createdByName = createdByName
        self.createdByEmail = createdByEmail
        self.name = name
        self.sizeInKb = sizeInKb
        self.url = url
        self.urlExpiresInMillis = urlExpiresInMillis
    }
    
    convenience init(from attachment: AttachmentDTO) {
        self.init(
            id: attachment.id,
            parentId: attachment.parentId,
            attachmentType: attachment.attachmentType,
            attachmentSubType: attachment.attachmentSubType,
            mimeType: attachment.mimeType,
            parentType: attachment.parentType,
//            createdAt: attachment.createdAt,
            createdByName: attachment.createdBy?.name,
            createdByEmail: attachment.createdBy?.email,
            name: attachment.name,
            sizeInKb: attachment.sizeInKb,
            url: attachment.url,
            urlExpiresInMillis: attachment.urlExpiresInMillis
        )
    }
}

// MARK: - Codable DTOs (Network)

public struct DiscussionDTO: Codable, Identifiable, Hashable, Sendable {
    public let accessLevel: String?
    public let id: Int
    public let comments: [CommentDTO]?
    public let commentAttachments: [AttachmentDTO]?
    public let commentCount: Int?
    public let createdBy: UserRef?
    public let lastCommentedAt: String
    public let lastCommentedUser: UserRef?
    public let parentId: Int?
    public let parentType: String?
    public let readOnly: Bool?
    public let title: String?
    
    /// This fields when true means that the value is not synchronised yet
    public var publishPending: Bool?
    
    public init(from cached: CachedDiscussionDTO) {
        self.accessLevel = cached.accessLevel
        self.id = cached.id
        self.commentCount = cached.commentCount
        self.parentId = cached.parentId
        self.parentType = cached.parentType
        self.readOnly = cached.readOnly
        self.lastCommentedAt = cached.lastCommentedAt
        self.title = cached.title

        self.createdBy = (cached.createdByName != nil || cached.createdByEmail != nil)
            ? UserRef(email: cached.createdByEmail, name: cached.createdByName)
            : nil

        self.lastCommentedUser = (cached.lastCommentedUserName != nil || cached.lastCommentedUserEmail != nil)
            ? UserRef(email: cached.lastCommentedUserEmail, name: cached.lastCommentedUserName)
            : nil

        self.comments = cached.comments.map { CommentDTO(from: $0) }
        self.commentAttachments = cached.commentAttachments.map { AttachmentDTO(from: $0) }
        self.publishPending = false
    }
    
    public init(from value: Discussion) {
        self.accessLevel = value.accessLevel
        self.id = value.id
        self.commentCount = value.commentCount
        self.parentId = value.parentId
        self.parentType = value.parentType
        self.readOnly = value.readOnly
        self.lastCommentedAt = value.lastCommentedAt
        self.title = value.title

        self.createdBy = value.createdBy.map { UserRef(email: $0.email, name: $0.name) }
        self.lastCommentedUser = value.lastCommentedUser.map { UserRef(email: $0.email, name: $0.name) }
        self.comments = value.comments?.map { CommentDTO(from: $0) }
        self.commentAttachments = value.commentAttachments?.map { AttachmentDTO(from: $0) }
        self.publishPending = false
    }
        
    public init(from value: CachedSheetDiscussionToPublishDTO) {
        
        let comment: CommentDTO = CommentDTO(from: value)
        
        self.accessLevel = ""
        self.id = value.id
        self.comments = [comment]
        self.commentAttachments = []
        self.commentCount = nil
        self.createdBy = .init(email: nil, name: value.userName)
        self.lastCommentedAt = comment.createdAt ?? ""
        self.lastCommentedUser = nil
        self.parentId = value.parentId
        self.parentType = value.parentType.rawValue
        self.readOnly = nil
        self.title = comment.text
        self.publishPending = true
    }
}

// MARK: - CommentDTO
public struct CommentDTO: Codable, Identifiable, Hashable, Sendable {
    public var id: Int
    public var discussionId: Int?
    public var text: String
    public var createdAt: String?
    public var modifiedAt: String?
    public var createdBy: UserRef?
    public var attachments: [AttachmentDTO]?

    // From API model
    public init(from comment: Comment) {
        self.id = comment.id
        self.discussionId = comment.discussionId ?? nil
        self.text = comment.text
        self.createdAt = comment.createdAt
        self.modifiedAt = comment.modifiedAt
        self.createdBy = UserRef(email: comment.createdBy?.email, name: comment.createdBy?.name)
        self.attachments = comment.attachments?.map { AttachmentDTO(from: $0) } ?? []
    }

    // From Cached model
    public init(from cached: CachedCommentDTO) {
        self.id = cached.id
        self.discussionId = cached.discussionId ?? 0
        self.text = cached.text ?? ""
        self.createdAt = cached.createdAt
        self.modifiedAt = cached.modifiedAt
        self.createdBy = UserRef(email: cached.createdByEmail, name: cached.createdByName)
        self.attachments = cached.attachments.map { AttachmentDTO(from: $0) }
    }
    
    // From locally created model
    public init(from cached: CachedSheetDiscussionToPublishDTO) {
        self.id = UUID().hashValue
        self.text = cached.comment.text
        self.createdAt = cached.dateTime.ISO8601Format()
        self.createdBy = .init(email: nil, name: cached.userName)
    }
}

// MARK: - AttachmentDTO
public struct AttachmentDTO: Codable, Identifiable, Hashable, Sendable {
    public var id: Int
    public var parentId: Int
    public var attachmentType: String
    public var attachmentSubType: String?
    public var mimeType: String?
    public var parentType: String
    public var createdAt: String?
    public var createdBy: UserRef?
    public var name: String
    public var sizeInKb: Int?
    public var url: String?
    public var urlExpiresInMillis: Int?

    // From API model
    public init(from attachment: Attachment) {
        self.id = attachment.id
        self.parentId = attachment.parentId
        self.attachmentType = attachment.attachmentType
        self.attachmentSubType = attachment.attachmentSubType
        self.mimeType = attachment.mimeType
        self.parentType = attachment.parentType
        self.createdAt = attachment.createdAt
        self.createdBy = UserRef(email: attachment.createdBy?.email ?? "", name: attachment.createdBy?.name ?? "")
        self.name = attachment.name
        self.sizeInKb = attachment.sizeInKb
        self.url = attachment.url
        self.urlExpiresInMillis = attachment.urlExpiresInMillis
    }

    // From Cached model
    public init(from cached: CachedAttachmentDTO) {
        self.id = cached.id
        self.parentId = cached.parentId ?? 0
        self.attachmentType = cached.attachmentType ?? ""
        self.attachmentSubType = cached.attachmentSubType
        self.mimeType = cached.mimeType
        self.parentType = cached.parentType ?? ""
        self.createdAt = cached.createdAt
        self.createdBy = UserRef(email: cached.createdByEmail ?? "", name: cached.createdByName ?? "")
        self.name = cached.name ?? ""
        self.sizeInKb = cached.sizeInKb
        self.url = cached.url
        self.urlExpiresInMillis = cached.urlExpiresInMillis
    }
}

public struct UserRef: Codable, Hashable, Sendable {
    public let email: String?
    public let name: String?
}
