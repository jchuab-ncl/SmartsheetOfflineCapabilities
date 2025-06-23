//
//  Dependencies.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation

/// A store of dependencies to be accessed by key.
public struct Dependencies {
    
    // MARK: Properties
    
    private var storage: [ObjectIdentifier: Any] = [:]
    
    /// A shared instance of `Dependencies`.
    public static var shared = Self()
    
    // MARK: Subscript(s)
    
    /// Allows accessing a dependency by key.
    /// - Parameter key: A key type for which to access its associated dependency.
    public subscript<Key: DependencyKey>(key: Key.Type) -> Key.DataType {
        get {
            if let dependency = storage[ObjectIdentifier(key)] as? Key.DataType {
                return dependency
            } else if let dependency = key.defaultValue {
                return dependency
            }
            fatalError("The requested dependency for key: \(key) has not been set.")
        }
        set(newValue) {
            storage[ObjectIdentifier(key)] = newValue
        }
    }
}
