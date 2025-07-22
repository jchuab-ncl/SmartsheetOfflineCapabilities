//
//  SmartsheetOfflineCapabilitiesApp.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import SwiftData
import SwiftUI

@main
struct SmartsheetOfflineCapabilitiesApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([CachedSheet.self])
        let config = ModelConfiguration("SmartsheetOffline", schema: schema)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

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
