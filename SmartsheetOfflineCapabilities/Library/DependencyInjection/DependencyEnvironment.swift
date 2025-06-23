//
//  DependencyEnvironment.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

struct DependencyEnvironment {
    static func configureDependencies() {
        let apiClient = HTTPApiClient()
        Dependencies.shared.authenticationService = AuthenticationService(httpApiClient: apiClient)
    }
}
