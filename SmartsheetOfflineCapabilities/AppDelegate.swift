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
        
        if let url = launchOptions?[.url] as? URL {
            print("Deep Link URL: \(url)")
            
            do {
                try Dependencies.shared.authenticationService.handleOAuthCallback(url: url)
            } catch {
                // TODO: Handle error
            }
        }
        
        DependencyEnvironment.configureDependencies()
        return true
    }
    
//    func application(
//        _ application: UIApplication,
//        open url: URL,
//        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
//    ) -> Bool {
//        
//        print("🔗 Received URL: \(url.absoluteString)")
//        
//        Dependencies.shared.authenticationService.handleOAuthCallback(url: url)
//        
//        return true
//    }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        print("🔗 Received URL: \(url.absoluteString)")
//        
//        do {
//            try Dependencies.shared.authenticationService.handleOAuthCallback(url: url)
//        } catch {
//            // TODO: Handle error
//        }
//        
//        return true
//    }
}
