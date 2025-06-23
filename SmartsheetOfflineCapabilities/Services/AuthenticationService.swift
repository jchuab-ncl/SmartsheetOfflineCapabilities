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
            print("Missing ClientID or redirectURI in Info.plist")
            currentErrorMessage = "Missing ClientID or redirectURI in Info.plist"
            return
        }

        let responseType = "code"
        let scopes = [
            "READ_SHEETS",
            "WRITE_SHEETS"
        ]
        let scopeString = scopes.joined(separator: " ")
        let state = UUID().uuidString

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
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            
            currentErrorMessage = "Authorization code not found in callback URL."
            print("Authorization code not found in callback URL.")
            
            return
        }

        exchangeCodeForToken(code: code)
    }

    /// Exchanges an authorization code for an access token using Smartsheet's API.
    /// - Parameter code: The authorization code received from the OAuth login flow.
    private func exchangeCodeForToken(code: String) {
        guard
            let clientID = SecretsLoader.shared.get(.smartsheetsClientId),
            let clientSecret = SecretsLoader.shared.get(.smartsheetsSecret),
            let redirectURI = SecretsLoader.shared.get(.smartsheetsCallbackURL)
        else {
            print("Missing ClientID, ClientSecret or RedirectURI in Info.plist")
            return
        }

        let tokenURL = "https://api.smartsheet.com/2.0/token"

        let bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientID,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: []) else {
            print("Failed to serialize token request body.")
            return
        }

        Task {
            let result = await httpApiClient.request(
                url: tokenURL,
                method: .POST,
                headers: ["Content-Type": "application/json"],
                queryParameters: nil,
                body: bodyData
            )

            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print("Token response: \(json)")
                    // TODO: Store access token securely
                } else {
                    print("Failed to decode token response")
                }
            case .failure(let error):
                print("Token request failed: \(error)")
            }
        }
    }
}
