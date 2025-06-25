//
//  InitialViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 25/06/25.
//

import Combine
import Foundation

final class InitialViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let authenticationService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Published Properties
    
    @Published var status: ProgressStatus = .initial
    @Published var errorMessage: String?
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
                    self?.presentNextScreen = true
                } else {
                    self?.errorMessage = result.message.description
                }
            })
            .store(in: &cancellables)
    }
        
    @MainActor
    func tryAutoLogin() {
        Task {
            status = .loading
            do {
                try authenticationService.autoLogin()
            } catch let error as AuthenticationServiceMessage {
                print(error)
            }
        }
    }
}
