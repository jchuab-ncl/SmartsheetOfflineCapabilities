//
//  AuthenticationService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import SwiftData
import SwiftUI

public protocol AuthenticationServiceProtocol {
    var resultType: Protected<AuthenticationServiceResultType> { get }
    var cachedUserDTO: CachedUserDTO? { get }
    
    func setupModelContext(modelContext: ModelContext)
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
    
    private var modelContext: ModelContext?
    private let httpApiClient: HTTPApiClientProtocol
    private let infoPListLoader: InfoPlistLoaderProtocol
    private let keychainService: KeychainServiceProtocol
    private var code: String = "EMPTY"
    
    /// Used to set the value locally
    @Protected private(set) var currentResult: AuthenticationServiceResultType = .init(message: .empty, status: .initial)
    
    // MARK: Public properties
    
    public var cachedUserDTO: CachedUserDTO?
    
    /// Used to observe changes externally
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
            
    func setupModelContext(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
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
        
        guard let authUrl = infoPListLoader.get(.smartsheetsAuthUrl) else {
            try publishError(.invalidAuthURL)
            return
        }
        
        var components = URLComponents(string: "\(authUrl)/b/authorize")
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
                let isInternetAvailable = await httpApiClient.isInternetAvailable()
                if isInternetAvailable {
                    try await refreshToken()
                    await getCurrentLoggedUserOnline()
                    publish(.storedCredentialsFound, .loading)
                } else {
                    await getCurrentUserFromStorage()
                    publish(.storedCredentialsFound, .loading)
                }
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
    
    private func getCurrentLoggedUserOnline() async {
        guard let accessToken = keychainService.load(for: .smartsheetAccessToken) else {
            print("❌ AuthenticationService: Access token not found")
            return
        }
        
        let url = "https://api.smartsheet.com/2.0/users/me"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        let result = await httpApiClient.request(url: url, method: .GET, headers: headers, queryParameters: nil)
        
        switch result {
        case .success(let data):
            do {
                let user = try JSONDecoder().decode(CachedUserDTO.self, from: data)
                self.cachedUserDTO = user
                
                /// Store the current user
                storeCurrentLoggedUser(user)
                
                print("✅ AuthenticationService: Successfully fetched current logged user")
            } catch {
                print("❌ AuthenticationService: Failed to decode user data - \(error.localizedDescription)")
            }
        case .failure(let error):
            print("❌ AuthenticationService: Failed to fetch current logged user - \(error.localizedDescription)")
        }
    }
    
    public func getCurrentUserFromStorage() async {
        do {
            return try await MainActor.run {
                let descriptor = FetchDescriptor<CachedUser>()
                let results = try modelContext?.fetch(descriptor)

                guard let cachedUser = results?.first else {
                    print("⚠️ No CachedUser found in storage.")
                    return
                }

                self.cachedUserDTO = CachedUserDTO(
                    id: cachedUser.id,
                    account: cachedUser.account.map {
                        AccountDTO(id: $0.id, name: $0.name)
                    } ?? AccountDTO(id: 0, name: ""),
                    admin: cachedUser.admin,
                    alternateEmails: [], //TODO: Update
                    company: cachedUser.company,
                    customWelcomeScreenViewed: cachedUser.customWelcomeScreenViewed,
                    department: cachedUser.department,
                    email: cachedUser.email,
                    firstName: cachedUser.firstName,
                    groupAdmin: cachedUser.groupAdmin,
                    jiraAdmin: cachedUser.jiraAdmin,
                    lastLogin: cachedUser.lastLogin,
                    lastName: cachedUser.lastName,
                    licensedSheetCreator: cachedUser.licensedSheetCreator,
                    locale: cachedUser.locale,
                    mobilePhone: cachedUser.mobilePhone,
                    profileImage: nil, //TODO: Update
                    resourceViewer: cachedUser.resourceViewer,
                    role: cachedUser.role,
                    salesforceAdmin: cachedUser.salesforceAdmin,
                    salesforceUser: cachedUser.salesforceUser,
                    sheetCount: cachedUser.sheetCount,
                    timeZone: cachedUser.timeZone,
                    title: cachedUser.title,
                    workPhone: cachedUser.workPhone,
                    data: nil // TODO: Update
                )
            }
        } catch {
            print("❌ Error fetching current user from storage: \(error)")
            return
        }
    }
    
    
    // MARK: Private methods
    
    private func storeCurrentLoggedUser(_ user: CachedUserDTO) {
        Task { @MainActor in
            do {
                // Fetch all CachedUser entities
                let existing = try modelContext?.fetch(FetchDescriptor<CachedUser>())
                // Delete all existing
                existing?.forEach { modelContext?.delete($0) }
                // Create new CachedUser from DTO
                let cachedUser = CachedUser(
                    id: user.id,
                    email: user.email,
                    firstName: user.firstName,
                    lastName: user.lastName
                )
                modelContext?.insert(cachedUser)
                try modelContext?.save()
                print("✅ Stored current logged user in SwiftData")
            } catch {
                print("❌ Failed to store current logged user in SwiftData: \(error)")
            }
        }
    }
    
    private func tokensAreStored() -> Bool {
        let smartsheetAccessToken = keychainService.load(for: .smartsheetAccessToken)
        let smartsheetRefreshToken = keychainService.load(for: .smartsheetRefreshToken)
        
        return smartsheetAccessToken != nil && smartsheetRefreshToken != nil
    }
    
    /// Exchanges an authorization code for an access token using Smartsheet's API.
    /// - Parameter code: The authorization code received from the OAuth login flow.
    private func exchangeCodeForToken(code: String, refreshToken: String = "", grantType: GrantType = .authorizationCode) throws {
        guard
            let clientID = infoPListLoader.get(.smartsheetsClientId),
            let clientSecret = infoPListLoader.get(.smartsheetsSecret)
        else {
            try publishError(.missingClientIDOrSecret)
            return
        }
        
        let tokenURL = "https://api.smartsheet.com/2.0/token"
        
        var queryParameters = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": grantType.rawValue,
        ]
        
        if code.isNotEmpty {
            queryParameters["code"] = code
        }
        
        if refreshToken.isNotEmpty {
            queryParameters["refresh_token"] = refreshToken
        }
        
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
                    
                    await getCurrentLoggedUserOnline()
                    
                    publish(.credentialsSuccessfullyValidated, .loading)
                }
            case .failure(_):
                //TODO: Handle case where user doesn't give permissions
                try publishError(.tokenRequestFailed)
            }
        }
    }
    
    private func refreshToken() async throws {
        guard let refreshTokenSaved = keychainService.load(for: .smartsheetRefreshToken) else {
            try publishError(.failedToLoadRefreshToken)
            return
        }
        
        try self.exchangeCodeForToken(code: "", refreshToken: refreshTokenSaved, grantType: .refreshToken)
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
