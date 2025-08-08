//
//  StringExtensionsTests.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/08/25.
//

import XCTest
@testable import SmartsheetOfflineCapabilities

final class StringExtensionTests: XCTestCase {

    // MARK: - isNotEmpty

    func test_isNotEmpty_trueWhenHasCharacters() {
        XCTAssertTrue("abc".isNotEmpty)
    }

    func test_isNotEmpty_falseWhenEmpty() {
        XCTAssertFalse("".isNotEmpty)
    }

    // MARK: - asFormattedDate (yyyy-MM-dd -> MM/dd/yy)

    func test_asFormattedDate_defaultFormats_success() {
        let input = "2025-04-12"
        let output = input.asFormattedDate() // defaults: in yyyy-MM-dd, out MM/dd/yy
        XCTAssertEqual(output, "04/12/25")
    }

    func test_asFormattedDate_customOutput_success() {
        let input = "2025-04-12"
        let output = input.asFormattedDate(inputFormat: "yyyy-MM-dd", outputFormat: "dd.MM.yyyy")
        XCTAssertEqual(output, "12.04.2025")
    }

    // MARK: - asFormattedDate (ISO -> friendly)

    func test_asFormattedDate_dateTimeISO_success() {
        let input = "2025-04-12T09:25:39Z"
        let output = input.asFormattedDate(
            inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ",
            outputFormat: "MM/dd/yy h:mm a"
        )
        // Note: output formatter uses system timezone; since input is Z (UTC),
        // the local time may shift. If you want stable tests across timezones,
        // consider setting a fixed TimeZone on output formatter in the extension.
        // Given current extension, we assert only the date part and hour string existence.
        XCTAssertTrue(output.hasPrefix("04/12/25 "), "Got: \(output)")
        XCTAssertTrue(output.contains("AM") || output.contains("PM"), "Got: \(output)")
    }

    // MARK: - Fallback behavior

    func test_asFormattedDate_invalidInput_returnsOriginal() {
        let input = "not-a-date"
        let output = input.asFormattedDate(inputFormat: "yyyy-MM-dd", outputFormat: "MM/dd/yy")
        XCTAssertEqual(output, "not-a-date")
    }

    func test_asFormattedDate_emptyInput_returnsEmpty() {
        let input = ""
        let output = input.asFormattedDate(inputFormat: "yyyy-MM-dd", outputFormat: "MM/dd/yy")
        XCTAssertEqual(output, "")
    }

    func test_asFormattedDate_whitespaceInput_success() {
        let input = " 2025-04-12 " // note spaces; the extension does not trim
        let output = input.asFormattedDate(inputFormat: "yyyy-MM-dd", outputFormat: "MM/dd/yy")
        XCTAssertEqual(output, "04/12/25")
    }
}
