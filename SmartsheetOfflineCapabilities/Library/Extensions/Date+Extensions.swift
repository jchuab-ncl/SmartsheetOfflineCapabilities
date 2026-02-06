//
//  Date+Extensions.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 05/02/26.
//

import Foundation

extension Date {
    /// Returns the date formatted as a string using the provided format.
    ///
    /// The default format is `MM/dd/yyyy hh:mm a`, which produces values like
    /// `11/12/2026 11:50:55 PM`.
    ///
    /// - Parameter format: The date format string to use.
    /// - Returns: A formatted date string.
    func asFormattedString(_ format: String = "MM/dd/yyyy hh:mm:ss.SSS a") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
