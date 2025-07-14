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
        
        // Given
        let expectation = self.expectation(description: "Waiting status updates")
        let sut = LoginViewModel()
        var allStatus: [ProgressStatus] = []

        // When
        sut.$status
            .collect(2)
            .sink { status in
                allStatus.append(contentsOf: status)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await sut.login()
        
        // Then        
        await fulfillment(of: [expectation], timeout: 3)
        XCTAssertEqual(allStatus, [.initial, .loading])
    }
}
