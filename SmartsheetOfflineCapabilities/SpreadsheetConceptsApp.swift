//
//  SmartsheetOfflineCapabilitiesApp.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import SwiftUI

@main
struct SmartsheetOfflineCapabilitiesApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
//    @StateObject private var httpClient: HTTPApiClient
//    @StateObject private var authenticationService: AuthenticationService

    init() {
//        let client = HTTPApiClient()
//        _httpClient = StateObject(wrappedValue: client)
//        _authenticationService = StateObject(wrappedValue: AuthenticationService(httpApiClient: client))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Dependencies.shared.authenticationService.handleOAuthCallback(url: url)
                }
//                .environmentObject(authenticationService)
        }
    }
}
