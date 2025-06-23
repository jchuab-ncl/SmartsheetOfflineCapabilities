//
//  SmartsheetOfflineCapabilitiesTests.swift
//  SmartsheetOfflineCapabilitiesTests
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import Testing
import XCTest
@testable import SmartsheetOfflineCapabilities

final class LoginViewModelTests: XCTestCase {

    func test_initialState_shouldBeEmptyAndNotLoggingIn() {
        let viewModel = LoginViewModel()
        XCTAssertTrue(viewModel.username.isEmpty)
        XCTAssertTrue(viewModel.password.isEmpty)
        XCTAssertFalse(viewModel.isLoggingIn)
        XCTAssertTrue(viewModel.isLoginDisabled)
    }

    func test_isLoginDisabled_shouldBeTrueIfEitherFieldIsEmpty() {
        let viewModel = LoginViewModel()
        
        viewModel.username = "user"
        viewModel.password = ""
        XCTAssertTrue(viewModel.isLoginDisabled)

        viewModel.username = ""
        viewModel.password = "pass"
        XCTAssertTrue(viewModel.isLoginDisabled)
    }

    func test_isLoginDisabled_shouldBeFalseIfBothFieldsAreFilled() {
        let viewModel = LoginViewModel()
        viewModel.username = "user"
        viewModel.password = "pass"
        XCTAssertFalse(viewModel.isLoginDisabled)
    }

    func test_login_shouldSetIsLoggingInToTrue() {
        let viewModel = LoginViewModel()
        XCTAssertFalse(viewModel.isLoggingIn)
        viewModel.login()
        XCTAssertTrue(viewModel.isLoggingIn)
    }
}

