//
//  AuthenticationServiceTests.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 30/06/25.
//

import Combine
import Foundation
import XCTest

@testable import SmartsheetOfflineCapabilities

final class AuthenticationServiceTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        //TODO: Create Keychain mock
        _ = KeychainService.shared.deleteAll()
    }
    
    override func tearDownWithError() throws {
        _ = KeychainService.shared.deleteAll()
    }
    
    func test_autoLogin_withStoredTokens_publishesStoredCredentialsFound() async {
        let expectation = expectation(description: "Waiting for result")
        
        _ = KeychainService.shared.save("access", for: .smartsheetAccessToken)
        _ = KeychainService.shared.save("refresh", for: .smartsheetRefreshToken)
        
        let httpApiClientMock = HTTPApiClientMock()
        let sut = AuthenticationService(httpApiClient: httpApiClientMock)
        
        sut.autoLogin()
        var resultToTest = AuthenticationServiceResultType(message: .empty, status: .initial)
        
        // When
        sut.$currentResult
            .sink { result in
                resultToTest = result
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        
        // Then
        await fulfillment(of: [expectation])
        
        XCTAssertEqual(resultToTest.message, .storedCredentialsFound)
        XCTAssertEqual(resultToTest.status, .loading)
    }
    
    func test_autoLogin_withoutTokens_publishesNoSavedCredentials() async {
        // Given
        let expectation = expectation(description: "Waiting for result")
        
        let httpApiClientMock = HTTPApiClientMock()
        let sut = AuthenticationService(httpApiClient: httpApiClientMock)
        
        var resultToTest = AuthenticationServiceResultType(message: .empty, status: .initial)
        
        // When
        sut.autoLogin()
        sut.$currentResult
            .sink { result in
                resultToTest = result
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation])
        
        XCTAssertEqual(resultToTest.message, .noSavedCredentials)
        XCTAssertEqual(resultToTest.status, .initial)
    }
    
    func test_handleOAuthCallback_withMissingCode_publishesAuthorizationCodeNotFound() {
        // Given
        let httpApiClientMock = HTTPApiClientMock()
        let sut = AuthenticationService(httpApiClient: httpApiClientMock)
        let url = URL(string: "smartsheetapp://oauth/callback?error=access_denied")!
        
        // When
        try? sut.handleOAuthCallback(url: url)
        let result = sut.resultType.wrappedValue
        
        // Then
        XCTAssertEqual(result.message, .authorizationCodeNotFound)
        XCTAssertEqual(result.status, .error)
    }
    
    func test_exchangeCodeForToken_fails_shouldPublishTokenRequestFailed() {
        // Given
        let expectation = expectation(description: "Should publish tokenRequestFailed")
        let mock = HTTPApiClientMock()
        mock.requestResult = .failure(URLError(.badServerResponse))
        let sut = AuthenticationService(httpApiClient: mock)
        var result: AuthenticationServiceResultType = .init(message: .empty, status: .initial)
        
        // When
        sut.$currentResult
            .sink {
                result = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        try? sut.handleOAuthCallback(url: URL(string: "smartsheetapp://oauth/callback?code=fake_code")!)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result.message, .tokenRequestFailed)
        XCTAssertEqual(result.status, .error)
    }
    
    func test_login_withoutInternet_shouldPublishLoginRequiresActiveConnection() async {
        // Given
        let expectation = expectation(description: "Should publish loginRequiresActiveConnection")
        let mock = HTTPApiClientMock()
        mock.isInternetAvailableResult = false
        let sut = AuthenticationService(httpApiClient: mock)
        var result: AuthenticationServiceResultType = .init(message: .empty, status: .initial)
        
        // When
        sut.$currentResult
            .sink {
                result = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        try? await sut.login()
        
        // Then
        await fulfillment(of: [expectation])
        XCTAssertEqual(result.message, .loginRequiresActiveConnection)
        XCTAssertEqual(result.status, .error)
    }
    
    func test_exchangeCodeForToken_succeeds_shouldPublishCredentialsSuccessfullyValidated() {
        // Given
        let expectation = expectation(description: "Should publish credentialsSuccessfullyValidated")
        let mock = HTTPApiClientMock()
        mock.requestResult = .success(HTTPApiClientMock.mockTokenResponse())
        let sut = AuthenticationService(httpApiClient: mock)
        var result: AuthenticationServiceResultType = .init(message: .empty, status: .initial)
        
        // When
        sut.$currentResult
            .sink {
                result = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        try? sut.handleOAuthCallback(url: URL(string: "smartsheetapp://oauth/callback?code=valid_code")!)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result.message, .credentialsSuccessfullyValidated)
        XCTAssertEqual(result.status, .success)
    }
    
    func test_exchangeCodeForToken_missingClientIDOrSecret_shouldPublishError() {
        // Given
        let expectation = expectation(description: "Should publish missingClientIDOrSecret")
        let httpApiClientMock = HTTPApiClientMock()
        
        let infoPlistLoaderMock = InfoPlistLoaderMock(mockData: [:]) // Simulating missing keys
        let sut = AuthenticationService(
            infoPListLoader: infoPlistLoaderMock,
            httpApiClient: httpApiClientMock
        )
        
        var result: AuthenticationServiceResultType = .init(message: .empty, status: .initial)

        // When
        sut.$currentResult
            .sink {
                result = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        try? sut.handleOAuthCallback(url: URL(string: "smartsheetapp://oauth/callback?code=fake_code")!)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result.message, .missingClientIDOrSecret)
        XCTAssertEqual(result.status, .error)
    }
}
