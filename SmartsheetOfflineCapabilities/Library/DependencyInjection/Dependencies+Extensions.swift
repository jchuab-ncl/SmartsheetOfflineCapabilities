//
//  Dependencies+Extensions.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

public enum AuthenticationServiceDependencyKey: DependencyKey {
    public typealias DataType = AuthenticationServiceProtocol
}

extension Dependencies {
    /// Analytics Service instance from `DependencyInjection`.
    public var authenticationService: AuthenticationServiceProtocol {
        get { self[AuthenticationServiceDependencyKey.self] }
        set { self[AuthenticationServiceDependencyKey.self] = newValue }
    }
}
