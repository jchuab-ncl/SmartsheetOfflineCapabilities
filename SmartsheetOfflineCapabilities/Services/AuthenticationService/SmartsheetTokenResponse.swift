//
//  SmartsheetTokenResponse.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 23/06/25.
//

struct SmartsheetTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}
