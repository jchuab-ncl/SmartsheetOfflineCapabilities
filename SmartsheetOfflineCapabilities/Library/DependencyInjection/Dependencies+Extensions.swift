//
//  Dependencies+Extensions.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

/// AuthenticationService
public enum AuthenticationServiceDependencyKey: DependencyKey {
    public typealias DataType = AuthenticationServiceProtocol
}

extension Dependencies {
    /// Authentication Service instance from `Dependencies`.
    public var authenticationService: AuthenticationServiceProtocol {
        get { self[AuthenticationServiceDependencyKey.self] }
        set { self[AuthenticationServiceDependencyKey.self] = newValue }
    }
}

/// HTTPApiClient
public enum HTTPApiClientDependencyKey: DependencyKey {
    public typealias DataType = HTTPApiClientProtocol
}

extension Dependencies {
    /// HTTPApiClient instance from `Dependencies`.
    public var httpApiClient: HTTPApiClientProtocol {
        get { self[HTTPApiClientDependencyKey.self] }
        set { self[HTTPApiClientDependencyKey.self] = newValue }
    }
}

/// InfoPListLoader
public enum InfoPlistLoaderDependencyKey: DependencyKey {
    public typealias DataType = InfoPlistLoaderProtocol
}

extension Dependencies {
    /// InfoPListLoader instance from `Dependencies`.
    public var infoPlistLoader: InfoPlistLoaderProtocol {
        get { self[InfoPlistLoaderDependencyKey.self] }
        set { self[InfoPlistLoaderDependencyKey.self] = newValue }
    }
}

/// KeychainService
public enum KeychainServiceDependencyKey: DependencyKey {
    public typealias DataType = KeychainServiceProtocol
}

extension Dependencies {
    /// KeychainService instance from `Dependencies`.
    public var keychainService: KeychainServiceProtocol {
        get { self[KeychainServiceDependencyKey.self] }
        set { self[KeychainServiceDependencyKey.self] = newValue }
    }
}

/// SheetService
public enum SheetServiceDependencyKey: DependencyKey {
    public typealias DataType = SheetServiceProtocol
}

extension Dependencies {
    /// SheetService instance from `Dependencies`.
    public var sheetService: SheetServiceProtocol {
        get { self[SheetServiceDependencyKey.self] }
        set { self[SheetServiceDependencyKey.self] = newValue }
    }
}

/// ServerInfoFormatParserService
public enum ServerInfoFormatParserServiceDependencyKey: DependencyKey {
    public typealias DataType = ServerInfoFormatParserProtocol
}

extension Dependencies {
    /// SheetService instance from `Dependencies`.
    public var serverInfoFormatParserService: ServerInfoFormatParserProtocol {
        get { self[ServerInfoFormatParserServiceDependencyKey.self] }
        set { self[ServerInfoFormatParserServiceDependencyKey.self] = newValue }
    }
}
