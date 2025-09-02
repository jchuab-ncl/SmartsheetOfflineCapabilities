//
//  CachedUser.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 29/08/25.
//

import Foundation
import SwiftData

public struct CachedUserDTO: Identifiable, Hashable, Sendable, Codable {
    public var id: Int
    public var account: AccountDTO?
    public var admin: Bool?
    public var alternateEmails: [AlternateEmailDTO]?
    public var company: String?
    public var customWelcomeScreenViewed: Bool?
    public var department: String?
    public var email: String?
    public var firstName: String?
    public var groupAdmin: Bool?
    public var jiraAdmin: Bool?
    public var lastLogin: String?
    public var lastName: String?
    public var licensedSheetCreator: Bool?
    public var locale: String?
    public var mobilePhone: String?
    public var profileImage: ProfileImageDTO?
    public var resourceViewer: Bool?
    public var role: String?
    public var salesforceAdmin: Bool?
    public var salesforceUser: Bool?
    public var sheetCount: Int?
    public var timeZone: String?
    public var title: String?
    public var workPhone: String?
    public var data: [UserGroupDTO]?
}

public struct AccountDTO: Hashable, Codable, Sendable {
    public var id: Int
    public var name: String?
    public var accountType: String?
    public var status: String?
}

public struct AlternateEmailDTO: Hashable, Codable, Sendable {
    public var email: String?
    public var confirmed: Bool?
    public var primary: Bool?
}

public struct ProfileImageDTO: Hashable, Codable, Sendable {
    public var url: String?
    public var height: Int?
    public var width: Int?
}

public struct GroupDTO: Hashable, Codable, Sendable {
    public var id: Int
    public var name: String?
}

public struct UserGroupDTO: Identifiable, Hashable, Sendable, Codable {
    public var id: Int
    public var name: String
    public var description: String
    public var owner: String
    public var ownerId: Int
    public var createdAt: Date
    public var modifiedAt: Date
}

@Model
public final class CachedUser {
    @Attribute(.unique) public var id: Int
    public var account: Account?
    public var admin: Bool?
    public var alternateEmails: [AlternateEmail]?
    public var company: String?
    public var customWelcomeScreenViewed: Bool?
    public var department: String?
    public var email: String?
    public var firstName: String?
    public var groupAdmin: Bool?
    public var jiraAdmin: Bool?
    public var lastLogin: String?
    public var lastName: String?
    public var licensedSheetCreator: Bool?
    public var locale: String?
    public var mobilePhone: String?
    public var profileImage: ProfileImage?
    public var resourceViewer: Bool?
    public var role: String?
    public var salesforceAdmin: Bool?
    public var salesforceUser: Bool?
    public var sheetCount: Int?
    public var timeZone: String?
    public var title: String?
    public var workPhone: String?
    public var data: [String: String]?

    public init(
        id: Int,
        account: Account? = nil,
        admin: Bool? = nil,
        alternateEmails: [AlternateEmail]? = nil,
        company: String? = nil,
        customWelcomeScreenViewed: Bool? = nil,
        department: String? = nil,
        email: String? = nil,
        firstName: String? = nil,
        groupAdmin: Bool? = nil,
        jiraAdmin: Bool? = nil,
        lastLogin: String? = nil,
        lastName: String? = nil,
        licensedSheetCreator: Bool? = nil,
        locale: String? = nil,
        mobilePhone: String? = nil,
        profileImage: ProfileImage? = nil,
        resourceViewer: Bool? = nil,
        role: String? = nil,
        salesforceAdmin: Bool? = nil,
        salesforceUser: Bool? = nil,
        sheetCount: Int? = nil,
        timeZone: String? = nil,
        title: String? = nil,
        workPhone: String? = nil,
        data: [String: String]? = nil
    ) {
        self.id = id
        self.account = account
        self.admin = admin
        self.alternateEmails = alternateEmails
        self.company = company
        self.customWelcomeScreenViewed = customWelcomeScreenViewed
        self.department = department
        self.email = email
        self.firstName = firstName
        self.groupAdmin = groupAdmin
        self.jiraAdmin = jiraAdmin
        self.lastLogin = lastLogin
        self.lastName = lastName
        self.licensedSheetCreator = licensedSheetCreator
        self.locale = locale
        self.mobilePhone = mobilePhone
        self.profileImage = profileImage
        self.resourceViewer = resourceViewer
        self.role = role
        self.salesforceAdmin = salesforceAdmin
        self.salesforceUser = salesforceUser
        self.sheetCount = sheetCount
        self.timeZone = timeZone
        self.title = title
        self.workPhone = workPhone
        self.data = data
    }
}

@Model
public final class Account {
    @Attribute(.unique) public var id: Int
    public var name: String?
    public var accountType: String?
    public var status: String?

    public init(
        id: Int,
        name: String? = nil,
        accountType: String? = nil,
        status: String? = nil
    ) {
        self.id = id
        self.name = name
        self.accountType = accountType
        self.status = status
    }
}

@Model
public final class AlternateEmail {
    public var email: String?
    public var confirmed: Bool?
    public var primary: Bool?

    public init(
        email: String? = nil,
        confirmed: Bool? = nil,
        primary: Bool? = nil
    ) {
        self.email = email
        self.confirmed = confirmed
        self.primary = primary
    }
}

@Model
public final class ProfileImage {
    public var url: String?
    public var height: Int?
    public var width: Int?

    public init(
        url: String? = nil,
        height: Int? = nil,
        width: Int? = nil
    ) {
        self.url = url
        self.height = height
        self.width = width
    }
}

@Model
public final class Group {
    @Attribute(.unique) public var id: Int
    public var name: String?

    public init(
        id: Int,
        name: String? = nil
    ) {
        self.id = id
        self.name = name
    }
}

@Model
public final class UserGroup {
    @Attribute(.unique) public var id: Int
    public var name: String
//    public var description: String
    public var owner: String
    public var ownerId: Int
    public var createdAt: Date
    public var modifiedAt: Date

    init(id: Int, name: String, description: String, owner: String, ownerId: Int, createdAt: Date, modifiedAt: Date) {
        self.id = id
        self.name = name
//        self.description = description
        self.owner = owner
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
