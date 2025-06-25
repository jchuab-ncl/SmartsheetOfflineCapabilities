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

    init() {

    }

    var body: some Scene {
        WindowGroup {
            InitialView()
                .onOpenURL { url in
                    do {
                        try Dependencies.shared.authenticationService.handleOAuthCallback(url: url)
                    } catch {
                        //TODO: Handle error
                    }
                }
        }
    }
}
