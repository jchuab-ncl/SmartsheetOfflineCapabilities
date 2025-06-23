//
//  SmartsheetOfflineCapabilitiesUITests.swift
//  SmartsheetOfflineCapabilitiesUITests
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import XCTest

import XCTest

final class LoginViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func test_loginScreen_displaysAllFieldsAndButton() throws {
        XCTAssertTrue(app.buttons["Login"].exists)
    }

    func test_loginButton_isEnabledByDefault() throws {
        let loginButton = app.buttons["Login"]
        XCTAssertTrue(loginButton.isEnabled)
    }
    
    // TODO: Create a test to validate if the button is disable while the login is in progress,
    // validate also if the progressview is visible
}
