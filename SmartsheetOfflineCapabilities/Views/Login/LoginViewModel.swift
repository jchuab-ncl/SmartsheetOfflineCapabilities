//
//  LoginViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 09/06/25.
//

import Combine
import Foundation

final class LoginViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let authenticationService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Published Properties
    
    @Published var status: ProgressStatus = .initial
    @Published var message: String?
    @Published var messageIcon: String?
    @Published var presentNextScreen: Bool = false
       
    // MARK: Initializers
    
    /// Initializes the LoginViewModel with a provided AuthenticationServiceProtocol.
    /// Sets up a subscription to receive and react to error message changes from the authentication service.
    /// - Parameter authenticationService: The service used to handle authentication logic. Defaults to the shared dependency.
    init(
        authenticationService: AuthenticationServiceProtocol = Dependencies.shared.authenticationService
    ) {
        self.authenticationService = authenticationService
        
        authenticationService.resultType
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] result in
                self?.status = result.status
                
                if result.message == .storedCredentialsFound || result.status == .success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.presentNextScreen = true
                    }
                }
                self?.message = "\(result.status.icon) \(result.message.description)"
            })
            .store(in: &cancellables)
    }
    
    // MARK: Public methods

    @MainActor
    func login() {
        Task {
            status = .loading
            do {
                try await authenticationService.login()
            } catch let error as AuthenticationServiceMessage {
                self.message = error.rawValue
                status = .initial
            }
        }
    }
    
    @MainActor
    func onAppear() {
        Task {
            status = .loading
                        
            // Check if the app is launching for the first time after installation.
            // If so, clear all Keychain data and mark the app as having launched to prevent future deletions.
            if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
                // First launch after install — clean keychain
                let _ = KeychainService.shared.deleteAll()
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            }
            
            authenticationService.autoLogin()
        }
    }
}
