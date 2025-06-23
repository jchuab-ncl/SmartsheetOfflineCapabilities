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
    
    @Published var isLoginInProgress: Bool = false
    @Published var errorMessage: String?
    @Published var presentNextScreen: Bool = false
       
    // MARK: Initializers
    
    
    init(
        authenticationService: AuthenticationServiceProtocol = Dependencies.shared.authenticationService
    ) {
        self.authenticationService = authenticationService
        
        authenticationService.errorMessage
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] value in
                self?.errorMessage = value
                self?.isLoginInProgress = value.isEmpty
                self?.presentNextScreen = value.isEmpty
            })
            .store(in: &cancellables)
    }
    
    // MARK: Public methods

    func login() {
        isLoginInProgress = true
        authenticationService.login()
    }
    
}
