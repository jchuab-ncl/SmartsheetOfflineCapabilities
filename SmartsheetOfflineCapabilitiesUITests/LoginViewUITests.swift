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
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Login"].exists)
    }

    func test_loginButton_isDisabledByDefault() throws {
        let loginButton = app.buttons["Login"]
        XCTAssertFalse(loginButton.isEnabled)
    }

    func test_loginButton_enablesWhenFieldsAreFilled() throws {
        let usernameField = app.textFields["Username"]
        let passwordField = app.secureTextFields["Password"]
        let loginButton = app.buttons["Login"]

        usernameField.tap()
        usernameField.typeText("testuser")

        passwordField.tap()
        passwordField.typeText("password")

        XCTAssertTrue(loginButton.isEnabled)
    }

    func test_passwordVisibilityToggle() throws {
        let secureField = app.secureTextFields["PasswordSecure"]
        secureField.tap()
        secureField.typeText("password")
        XCTAssertTrue(secureField.waitForExistence(timeout: 2))
        
        let toggleButton = app.buttons["ShowHidePassword"]
        XCTAssertTrue(toggleButton.exists)
        toggleButton.tap()
        
        let plainField = app.textFields["Password"]
        XCTAssertTrue(plainField.exists)
    }
}
