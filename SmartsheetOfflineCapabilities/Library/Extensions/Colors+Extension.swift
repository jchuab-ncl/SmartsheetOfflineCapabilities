//
//  Colors+Extension.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 12/09/25.
//

import SwiftUI

/// Helper properties for `Color` attribute
public extension Color {
    /// Returns the given UIColor instance hex's value into String format
    var hexString: String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "FFFFFF"
        }
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        var alpha = Float(1.0)

        if components.count >= 4 {
            alpha = Float(components[3])
        }

        if alpha != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255), lroundf(alpha * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
        }
    }
    
    /// Initializes a Color using a hex string in the format #RRGGBB or #RRGGBBAA
    init(hex: String) {
        // Remove non-alphanumeric characters from the hex string
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        
        switch hex.count {
        case 3: // RGB (12-bit) e.g. "#123"
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        
        case 6: // RGB (24-bit) e.g. "#FF0000"
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        
        case 8: // RGBA (32-bit) e.g. "#FF000080"
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        
        default:
            // Return white if the format is incorrect
            (alpha, red, green, blue) = (255, 255, 255, 255)
        }

        // Initialize Color with the parsed values
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
    
    
}

