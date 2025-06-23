//
//  AuthenticationService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import SwiftUI

public protocol AuthenticationServiceProtocol {
    var errorMessage: Protected<String> { get }
    
    func login()
    func handleOAuthCallback(url: URL)
}

enum GrantType: String {
    case authorizationCode = "authorization_code"
    case refreshToken = "refresh_token"
}

/// A service responsible for managing OAuth-based authentication using Smartsheet's API.
/// Handles initiating the login flow, receiving the callback, and exchanging the authorization code for an access token.
/// - SeeAlso: https://developers.smartsheet.com/api/smartsheet/guides/advanced-topics/oauth#oauth-flow
class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: Private properties
    
    private let httpApiClient: HTTPApiClient
    private var code: String = "EMPTY"
    
    // MARK: Public properties
    
    @Protected private(set) var currentErrorMessage: String
    
    public var errorMessage: Protected<String> {
        $currentErrorMessage
    }
    
    // MARK: Initializers
    
    init(httpApiClient: HTTPApiClient) {
        self.httpApiClient = httpApiClient
        self.currentErrorMessage = ""
    }
    
    //MARK: Public methods
    
    /// Initiates the OAuth 2.0 login flow by constructing and opening the authorization URL.
    /// The user is redirected to Smartsheet's login/authorization page in a browser.
    /// On successful login, the app will receive a callback to the registered redirect URI containing the authorization code.
    func login() {
        guard
            let smartsheetsClientId = SecretsLoader.shared.get(.smartsheetsClientId)
                //            let smartsheetsSecret = SecretsLoader.shared.get(.smartsheetsSecret),
                //            let redirectURI = SecretsLoader.shared.get(.smartsheetsCallbackURL)
        else {
            publishError("Missing ClientID or redirectURI in Info.plist")
            return
        }
        
        let responseType = "code"
        let scopes = [
            "READ_SHEETS",
            "WRITE_SHEETS"
        ]
        let scopeString = scopes.joined(separator: " ")
        
        /// An arbitrary string of our choosing that is returned to us by the SmartsheetAPI. A successful roundtrip of this string helps ensure that our app initiated the request.
        guard let state = Bundle.main.bundleIdentifier else {
            return publishError("Bundle Identifier not found")
        }
        
        var components = URLComponents(string: "https://app.smartsheet.com/b/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: smartsheetsClientId),
            URLQueryItem(name: "response_type", value: responseType),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "state", value: state),
            //            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        
        guard let authURL = components?.url else {
            print("Invalid auth URL")
            return
        }
        
        UIApplication.shared.open(authURL)
        
        print(authURL)
    }
    
    /// Handles the OAuth redirect URI callback and extracts the authorization code.
    /// - Parameter url: The redirect URL received from the OAuth provider.
    func handleOAuthCallback(url: URL) {
        
        //TODO: Handle the case where the user clicks on "Doesn't allow"
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            
            publishError("Authorization code not found in callback URL.")
            return
        }
        
        exchangeCodeForToken(code: code)
    }
    
    /// Exchanges an authorization code for an access token using Smartsheet's API.
    /// - Parameter code: The authorization code received from the OAuth login flow.
    private func exchangeCodeForToken(code: String) {
        guard
            let clientID = SecretsLoader.shared.get(.smartsheetsClientId),
            let clientSecret = SecretsLoader.shared.get(.smartsheetsSecret)
        else {
            publishError("Missing ClientID, ClientSecret in Info.plist")
            return
        }
        
        let tokenURL = "https://api.smartsheet.com/2.0/token"
        
        let queryParameters = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": GrantType.authorizationCode.rawValue,
            "code": code
        ]
        
        Task {
            let result = await httpApiClient.request(
                url: tokenURL,
                method: .POST,
                headers: ["Content-Type": "application/json"],
                queryParameters: queryParameters
            )
            
            switch result {
            case .success(let data):
                if let tokenResponse = try? JSONDecoder().decode(SmartsheetTokenResponse.self, from: data) {
                    print("Token response: \(tokenResponse)")
                    let accessTokenSaved = KeychainService.shared.save(tokenResponse.accessToken, for: "smartsheet_access_token")
                    let refreshTokenSaved = KeychainService.shared.save(tokenResponse.refreshToken, for: "smartsheet_refresh_token")
                                        
                    if !accessTokenSaved {
                        publishError("❌ Failed to save access token to Keychain")
                        return
                    }
                    
                    if !refreshTokenSaved {
                        publishError("❌ Failed to save refresh token to Keychain")
                        return
                    }
                    
                    publishSuccess()
                }
            case .failure(let error):
                publishError("Token request failed: \(error)")
            }
        }
    }
    
    private func publishError(_ message: String) {
        print("AuthenticationService: \(message)")
        currentErrorMessage = message
    }
    
    private func publishSuccess() {
        print("AuthenticationService: exchangeCodeForToken succeeded.")
        currentErrorMessage = ""
    }
}
