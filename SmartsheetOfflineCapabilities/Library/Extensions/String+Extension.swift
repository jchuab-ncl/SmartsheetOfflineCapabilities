//
//  String+Extension.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 23/06/25.
//

import Foundation

extension String {
    /// Returns true if the string is not empty.
    var isNotEmpty: Bool {
        return !isEmpty
    }
    
    /// Converts a date string from a specified input format to a specified output format.
    ///
    /// - Parameters:
    ///   - inputFormat: The expected date format of the current string. Default is `"yyyy-MM-dd"`.
    ///   - outputFormat: The desired format to convert the date into. Default is `"MM/dd/yy"`.
    /// - Returns: A formatted date string if conversion is successful; otherwise, returns the original string.
    func asFormattedDate(
        inputFormat: String = "yyyy-MM-dd",
        outputFormat: String = "MM/dd/yy"
    ) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = inputFormat
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = outputFormat

        if let date = inputFormatter.date(from: self) {
            return outputFormatter.string(from: date)
        } else {
            return self
        }
    }
    
    func asDate(inputFormat: String = "yyyy-MM-dd'T'HH:mm:ss'Z'") -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = inputFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: self) ?? Date.distantPast
    }
    
    /// Converts a string to camelCase or PascalCase
    func camelCased(firstLetterUppercased: Bool = false) -> String {
        let parts = self
            .components(separatedBy: CharacterSet.alphanumerics.inverted) // split on spaces, dashes, underscores, etc.
            .filter { !$0.isEmpty }

        guard let first = parts.first?.lowercased() else {
            return ""
        }

        let rest = parts.dropFirst().map { $0.capitalized }
        let result = ([first] + rest).joined()
        if firstLetterUppercased, let firstChar = result.first {
            return String(firstChar).uppercased() + result.dropFirst()
        } else {
            return result
        }
    }
}
