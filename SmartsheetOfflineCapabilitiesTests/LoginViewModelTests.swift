//
//  SmartsheetOfflineCapabilitiesTests.swift
//  SmartsheetOfflineCapabilitiesTests
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import Combine
import Testing
import XCTest

@testable import SmartsheetOfflineCapabilities

final class LoginViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override class func setUp() {
        Dependencies.shared.authenticationService = AuthenticationService(httpApiClient: HTTPApiClientMock())
    }

    func test_initialState_shouldBeEmptyAndNotLoggingIn() {
        let viewModel = LoginViewModel()
        XCTAssertEqual(viewModel.status, .initial)
    }

    //TODO: This unit test need to be improved
    func test_login_shouldSetIsLoggingInToTrue() async {
        
        let expectation = self.expectation(description: "Waiting status updates")
        
        let sut = LoginViewModel()
        await sut.login()
        
        var allStatus: [ProgressStatus] = []
        
        // When
        sut.$status
            .collect(2)
            .sink {
                allStatus.append(contentsOf: $0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 1)
        
        XCTAssertEqual(allStatus, [.initial, .loading])
    }
}

