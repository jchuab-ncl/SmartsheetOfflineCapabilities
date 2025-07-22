//
//  AuthenticatedServiceErrors.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 25/06/25.
//

enum AuthenticationServiceMessage: String, Error {
    case accessTokenAndRefreshTokenLoaded = "Access token and refresh token loaded from keychain."
    case authorizationCodeNotFound = "Authorization code not found in callback URL."
    case bundleIdentifierNotFound = "Bundle Identifier not found."
    case credentialsSuccessfullyValidated = "Credentials successfully validated."
    case empty = ""    
    case failedToSaveAccessToken = "Failed to save access token to Keychain."
    case failedToSaveRefreshToken = "Failed to save refresh token to Keychain."
    case failedToLoadRefreshToken = "Failed to load refresh token from Keychain."
    case invalidAuthURL = "Invalid auth URL."
    case loginRequiresActiveConnection = "Login requires an active internet connection. Please connect to the internet and try again."
    case missingClientIDOrRedirectURI = "Missing ClientID or redirectURI in Info.plist."
    case missingClientIDOrSecret = "Missing ClientID, ClientSecret in Info.plist."
    case noSavedCredentials = "You don't have any saved credentials so you need an active internet connection to complete login."
    case smartsheetBaseURLNotFound = "Smartsheet Base URL not found in Info.plist."
    case storedCredentialsFound = "Stored credentials found. Loading spreadsheet data..."
    case tokenRequestFailed = "Token request failed."
    
    var description: String {
        self.rawValue
    }
}
