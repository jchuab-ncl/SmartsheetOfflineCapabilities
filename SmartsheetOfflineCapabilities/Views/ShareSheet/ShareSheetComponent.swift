//
//  ShareSheetComponent.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 05/02/26.
//

import SwiftUI

public struct ShareSheetComponent: UIViewControllerRepresentable {

    let items: [Any]
    
    public init(items: [Any]) {
        self.items = items
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
        
        let xPosition = UIScreen.main.bounds.width / 2.1 // Approximate value to calulate X Postion based on screen width
        let yPosition = UIScreen.main.bounds.height / 2.3 // Approximate value to calulate Y Postion based on screen height
        
        controller.popoverPresentationController?.sourceRect = CGRect(x: xPosition, y: yPosition, width: 200, height: 200)
        
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
