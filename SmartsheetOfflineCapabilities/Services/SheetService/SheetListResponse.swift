//
//  SheetListResponse.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

public struct SheetSource: Codable, Equatable {
    let id: Int
    let type: String
}

public struct Sheet: Codable, Equatable {
    let id: Int
    let accessLevel: String
    let createdAt: String
    let modifiedAt: String
    let name: String
    let permalink: String
    let version: Int?
    let source: SheetSource?
}

public struct SheetListResponse: Codable, Equatable {
    let pageNumber: Int
    let pageSize: Int
    let totalPages: Int
    let totalCount: Int
    let data: [Sheet]
}
