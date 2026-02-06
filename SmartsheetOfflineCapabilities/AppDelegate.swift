//
//  AppDelegate.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 17/06/25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        DependencyEnvironment.configureDependencies()
        
        if let url = launchOptions?[.url] as? URL {
            Dependencies.shared.logService.add(
                text: "Deep Link URL: \(url)",
                type: .info,
                context: String(describing: type(of: self))
            )
            
            do {
                try Dependencies.shared.authenticationService.handleOAuthCallback(url: url)
            } catch {
                Dependencies.shared.logService.add(
                    text: "Error handling OAuth callback for URL: \(url) / Error: \(error.localizedDescription)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
            }
        }
        return true
    }
}
