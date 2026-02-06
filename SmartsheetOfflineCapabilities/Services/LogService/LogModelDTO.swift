//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 05/02/26.
//

import Foundation
import SwiftData

/// SwiftData model representing a persisted log entry.
@Model
final class LogModelDTO {

    /// Unique identifier for the log entry.
    @Attribute(.unique)
    var id: UUID

    /// Date and time when the log was created.
    var dateTime: Date

    /// Log message content.
    var message: String

    /// Raw value of `LogEntryType`.
    /// Stored as `String` for SwiftData compatibility.
    var typeRawValue: String

    /// Optional context (e.g. "Sync", "Auth", "SheetService").
    var context: String

    init(
        dateTime: Date = Date(),
        message: String,
        type: LogEntryType,
        context: String
    ) {
        self.id = UUID()
        self.dateTime = dateTime
        self.message = message
        self.typeRawValue = type.rawValue
        self.context = context
    }

    /// Converts the stored raw value back to `LogEntryType`.
    var type: LogEntryType {
        LogEntryType(rawValue: typeRawValue) ?? .info
    }
}
