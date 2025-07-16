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
}
