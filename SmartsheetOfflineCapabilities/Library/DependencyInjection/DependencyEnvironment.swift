//
//  DependencyEnvironment.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

struct DependencyEnvironment {
    static func configureDependencies() {
        Dependencies.shared.logService = LogService()
        Dependencies.shared.httpApiClient = HTTPApiClient()
        Dependencies.shared.infoPlistLoader = InfoPlistLoader()
        Dependencies.shared.keychainService = KeychainService()
        
        Dependencies.shared.authenticationService = AuthenticationService()        
    }
}
