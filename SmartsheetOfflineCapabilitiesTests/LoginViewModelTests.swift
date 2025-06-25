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
        XCTAssertFalse(viewModel.status)
    }

    func test_login_shouldSetIsLoggingInToTrue() {
        let viewModel = LoginViewModel()
        XCTAssertFalse(viewModel.status)
        viewModel.login()
        XCTAssertTrue(viewModel.status)
    }
}

