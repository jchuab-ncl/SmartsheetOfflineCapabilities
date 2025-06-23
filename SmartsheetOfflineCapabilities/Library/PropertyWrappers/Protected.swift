//
//  Protected.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 20/06/25.
//

import Combine
import Foundation

/// A property wrapper that provides thread-safe read and write access to a value.
///
/// The `Protected` property wrapper ensures that any access to the wrapped value is thread-safe
/// by using an internal lock. It also acts as a publisher, allowing subscribers to receive updates
/// when the value changes.
@propertyWrapper
public final class Protected<Value>: Publisher {
    /// The kind of errors this publisher might publish.
    ///
    /// `Never` since this `Publisher` does not publish errors.
    public typealias Failure = Never

    /// The kind of values published by this publisher.
    public typealias Output = Value

    // MARK: - Private Properties

    private let lock = NSLock()
    private let subject = PassthroughSubject<Value, Never>()
    private var value: Value

    // MARK: - Properties

    /// A computed property that returns the `Protected<Value>` instance itself.
    ///
    /// This property provides a way to access the `Protected<Value>` instance
    /// when it is used as a property wrapper. The `projectedValue` can be useful
    /// for accessing the wrapped instance directly, allowing additional functionality
    /// or configurations.
    public var projectedValue: Protected<Value> {
        self
    }

    /// The contained value. Unsafe for anything more than direct read or write.
    public var wrappedValue: Value {
        get {
            read()
        }

        set {
            write(newValue)
        }
    }

    // MARK: Initializers

    /// Creates a new instance of the `Protected` property wrapper with the given value.
    ///
    /// This initializer sets the initial value for the property wrapped by `Protected`.
    ///
    /// - Parameter value: The initial value to be wrapped by the `Protected` property wrapper.
    public init(_ value: Value) {
        self.value = value
    }

    /// Creates a new instance of the `Protected` property wrapper with the given value.
    ///
    /// This initializer sets the initial value for the property wrapped by `Protected`.
    ///
    /// - Parameter wrappedValue: The initial value to be wrapped by the `Protected` property wrapper.
    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    // MARK: Instance methods

    /// Synchronously read  the contained value.
    ///
    /// - Returns: The current value.
    func read() -> Value {
        read { $0 }
    }

    /// Synchronously read or transform the contained value.
    ///
    /// - Parameter closure: The closure to execute.
    /// - Returns: The return value of the closure passed.
    func read<U>(_ closure: (Value) throws -> U) rethrows -> U {
        defer { lock.unlock() }

        lock.lock()
        return try closure(self.value)
    }

    /// Synchronously modify the protected value.
    ///
    /// - Parameter value: The new value.
    func write(_ value: Value) {
        write { $0 = value }
    }

    /// Synchronously modify the protected value.
    ///
    /// - Parameter closure: The closure to execute.
    /// - Returns: The modified value.
    @discardableResult
    func write<U>(_ closure: (inout Value) throws -> U) rethrows -> U {
        defer {
            subject.send(value)
            lock.unlock()
        }

        lock.lock()
        return try closure(&value)
    }

    // MARK: Publisher

    /// Attaches the specified subscriber to this publisher.
    ///
    /// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        subject.receive(subscriber: subscriber)
    }
}
