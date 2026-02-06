//
//  LogService.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 05/02/26.
//

import Foundation

public enum LogEntryType: String, Codable, CaseIterable {
    case all
    case debug
    case info
    case warning
    case error
}

public struct LogEntry: Identifiable {
    public var id = UUID()
    let dateTime: Date
    let message: String
    let type: LogEntryType
    let context: String
}

public protocol LogServiceProtocol {
    func add(text: String, type: LogEntryType, context: String)
    func deleteAll() -> Bool
    func getAll() -> [LogEntry]
}

/// Default implementation of `LogServiceProtocol`.
/// Responsible for persisting and retrieving application logs.
final class LogService: LogServiceProtocol {

    // MARK: - Properties

    private var logs: [LogEntry] = []

    // MARK: - Initializer

    /// Creates a new instance of `LogService`.
    init() {}
    
    // MARK: Private methods
    
    private func printLog(_ log: LogEntry) {
        let icon: String

        switch log.type {
        case .debug:
            icon = "🐞"
        case .info:
            icon = "ℹ️"
        case .warning:
            icon = "⚠️"
        case .error:
            icon = "❌"
        case .all:
            icon = ""
        }

        print("\(icon) \(log.dateTime.formatted()) [\(log.type.rawValue.uppercased())] [\(log.context)] \(log.message)")
    }

    // MARK: Public methods

    /// Persists a new log entry.
    /// - Parameters:
    ///   - text: Log message.
    ///   - type: Severity level.
    ///   - context: Logical context (e.g. "Sync", "Auth").
    func add(
        text: String,
        type: LogEntryType,
        context: String
    ) {
        let entry = LogEntry(
            dateTime: Date(),
            message: text,
            type: type,
            context: context
        )
        logs.append(entry)
        printLog(entry)
    }

    /// Returns all persisted logs ordered by most recent first.
    func getAll() -> [LogEntry] {
        return logs.sorted { $0.dateTime > $1.dateTime }
    }

    /// Deletes all logs.
    /// - Returns: `true` if deletion succeeded.
    func deleteAll() -> Bool {
        logs.removeAll()
        return true
    }
    
    //MARK: Private methods
    
    private static func extractTypeName(from fileID: String) -> String {
        // Example fileID: "SmartsheetOfflineCapabilities/InfoPlistLoader.swift"
        fileID
            .components(separatedBy: "/")
            .last?
            .replacingOccurrences(of: ".swift", with: "") ?? "Unknown"
    }
}
