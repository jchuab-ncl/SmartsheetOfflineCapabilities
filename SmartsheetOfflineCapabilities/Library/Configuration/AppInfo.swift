//
//  AppInfo.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 29/01/26.
//
import Foundation

/// Utility structure that provides access to basic application metadata
/// such as the current version and build number.
///
/// The values are read from the app’s Info.plist at runtime using `Bundle.main`.
/// If a value cannot be found, `"Unknown"` is returned as a safe fallback.
struct AppInfo {
    /// The marketing version of the app (CFBundleShortVersionString).
    ///
    /// Example: "1.3.0"
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// The internal build number of the app (CFBundleVersion).
    ///
    /// Example: "42"
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    static var versionBuildFormatted: String {
        "Version: \(version) (\(build))"
    }
}
