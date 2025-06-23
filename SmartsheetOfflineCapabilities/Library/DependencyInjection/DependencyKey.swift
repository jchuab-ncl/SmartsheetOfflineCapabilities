//
//  DependencyKey.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import Foundation

/// A key associated with a dependency value for lookup.
public protocol DependencyKey {
    /// The type of the dependency associated with the key.
    associatedtype DataType = Self

    /// A default value for they key.
    static var defaultValue: DataType? { get }
}

extension DependencyKey {
    /// Sets the defaultValue to nil by default.
    public static var defaultValue: DataType? {
        nil
    }
}
