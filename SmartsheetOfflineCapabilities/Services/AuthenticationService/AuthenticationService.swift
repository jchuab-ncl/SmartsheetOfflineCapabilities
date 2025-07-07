//
//  AuthenticationService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import SwiftUI

public protocol AuthenticationServiceProtocol {
    var resultType: Protected<AuthenticationServiceResultType> { get }
    
    func login() async throws
    func autoLogin()
    func handleOAuthCallback(url: URL) throws
}

enum GrantType: String {
    case authorizationCode = "authorization_code"
    case refreshToken = "refresh_token"
}

public struct AuthenticationServiceResultType: Equatable {
    var message: AuthenticationServiceMessage
    var status: ProgressStatus
}

/// A service responsible for managing OAuth-based authentication using Smartsheet's API.
/// Handles initiating the login flow, receiving the callback, and exchanging the authorization code for an access token.
/// - SeeAlso: https://developers.smartsheet.com/api/smartsheet/guides/advanced-topics/oauth#oauth-flow
class AuthenticationService: AuthenticationServiceProtocol {
   
    // MARK: Private properties
    
    private let httpApiClient: HTTPApiClientProtocol
    private let infoPListLoader: InfoPlistLoaderProtocol
    private let keychainService: KeychainServiceProtocol
    
    private var code: String = "EMPTY"
    
    // MARK: Public properties
    
    @Protected private(set) var currentResult: AuthenticationServiceResultType = .init(message: .empty, status: .initial)
    
    public var resultType: Protected<AuthenticationServiceResultType> {
        $currentResult
    }
        
    // MARK: Initializers
    
    /// Initializes the AuthenticationService with provided dependencies for HTTP requests, Info.plist loading, and secure storage.
    /// - Parameters:
    ///   - httpApiClient: The client responsible for performing network requests. Defaults to the shared dependency.
    ///   - infoPListLoader: The loader responsible for fetching configuration values from Info.plist. Defaults to the shared dependency.
    ///   - keychainService: The service used for securely storing authentication tokens. Defaults to the shared dependency.
    init(
        httpApiClient: HTTPApiClientProtocol = Dependencies.shared.httpApiClient,
        infoPListLoader: InfoPlistLoaderProtocol = Dependencies.shared.infoPlistLoader,
        keychainService: KeychainServiceProtocol = Dependencies.shared.keychainService
    ) {
        self.infoPListLoader = infoPListLoader
        self.keychainService = keychainService
        self.httpApiClient = httpApiClient
        self.currentResult.message = .empty
    }
    
    //MARK: Public methods
    
    /// Initiates the OAuth 2.0 login flow by constructing and opening the authorization URL.
    /// The user is redirected to Smartsheet's login/authorization page in a browser.
    /// On successful login, the app will receive a callback to the registered redirect URI containing the authorization code.
    func login() async throws {
        let isInternetAvailable = await httpApiClient.isInternetAvailable()
        guard isInternetAvailable else {
            try publishError(.loginRequiresActiveConnection)
            return
        }
        
        guard let smartsheetsClientId = infoPListLoader.get(.smartsheetsClientId)
        else {
            try publishError(.missingClientIDOrRedirectURI)
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
            try publishError(.bundleIdentifierNotFound)
            return
        }
        
        guard let baseUrl = infoPListLoader.get(.smartsheetsBaseUrl) else {
            try publishError(.invalidAuthURL)
            return
        }
        
        var components = URLComponents(string: "\(baseUrl)/b/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: smartsheetsClientId),
            URLQueryItem(name: "response_type", value: responseType),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "state", value: state),
        ]
        
        guard let authURL = components?.url else {
            print("Invalid auth URL")
            publish(.smartsheetBaseURLNotFound, .error)
            return
        }
        
        //TODO: Move that to viewModel
        await UIApplication.shared.open(authURL)
        
        print(authURL)
    }
    
    func autoLogin() {
        Task {
            // Forcing the screen to wait 1 second to give a better final UI/UX result
            try? await Task.sleep(nanoseconds: 1_000_000_000)
           
            if tokensAreStored() {
                publish(.storedCredentialsFound, .loading)
            } else {
                publish(.noSavedCredentials, .initial)
            }
        }
    }
        
    /// Handles the OAuth redirect URI callback and extracts the authorization code.
    /// - Parameter url: The redirect URL received from the OAuth provider.
    func handleOAuthCallback(url: URL) throws {
        
        //TODO: Handle the case where the user clicks on "Doesn't allow"
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            
            publish(.authorizationCodeNotFound, .error)
            return
        }
        
        try exchangeCodeForToken(code: code)
    }
    
    // MARK: Private methods
    
    private func tokensAreStored() -> Bool {
        let smartsheetAccessToken = keychainService.load(for: .smartsheetAccessToken)
        let smartsheetRefreshToken = keychainService.load(for: .smartsheetRefreshToken)
        
        return smartsheetAccessToken != nil && smartsheetRefreshToken != nil
    }
    
    /// Exchanges an authorization code for an access token using Smartsheet's API.
    /// - Parameter code: The authorization code received from the OAuth login flow.
    private func exchangeCodeForToken(code: String) throws {
        guard
            let clientID = infoPListLoader.get(.smartsheetsClientId),
            let clientSecret = infoPListLoader.get(.smartsheetsSecret)
        else {
            try publishError(.missingClientIDOrSecret)
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
                    let accessTokenSaved = keychainService.save(tokenResponse.accessToken, for: .smartsheetAccessToken)
                    let refreshTokenSaved = keychainService.save(tokenResponse.refreshToken, for: .smartsheetRefreshToken)
                                        
                    if !accessTokenSaved {
                        try publishError(.failedToSaveAccessToken)
                        return
                    }
                    
                    if !refreshTokenSaved {
                        try publishError(.failedToSaveRefreshToken)
                        return
                    }
                    
                    publish(.credentialsSuccessfullyValidated, .success)
                }
            case .failure(let error):
                //TODO: Handle case where user doesn't give permissions
                try publishError(.tokenRequestFailed)
            }
        }
    }
    
    private func publish(_ msg: AuthenticationServiceMessage, _ type: ProgressStatus) {
        print("\(type.icon) AuthenticationService: \(msg.description)")
        currentResult = .init(message: msg, status: type)
    }
    
    private func publishError(_ msg: AuthenticationServiceMessage) throws {
        print("❌ AuthenticationService: \(msg.description)")
        currentResult = .init(message: msg, status: .error)
        throw msg
    }
}
