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
    
//    @Published var username: String = "test"
//    @Published var password: String = "test"
    @Published var isLoggingIn: Bool = false
    @Published var errorMessage: String?
    @Published var presentNextScreen: Bool = false
    
    // MARK: Computed properties

//    var isLoginDisabled: Bool {
//        username.isEmpty || password.isEmpty
//    }
    
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
            })
            .store(in: &cancellables)
    }
    
    // MARK: Public methods

    func login() {
        isLoggingIn = true
        
        /// Testing error handling
//        errorMessage = "Incorrect username or password. Double check and try again."
        authenticationService.login()

        //TODO: Handling screen flow        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.isLoggingIn = false
//            self.presentNextScreen = true
//        }
    }
    
}
