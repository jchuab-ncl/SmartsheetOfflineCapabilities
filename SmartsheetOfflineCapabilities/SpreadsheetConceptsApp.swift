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
        let schema = Schema([
            CachedSheet.self,
            CachedSheetContent.self,
            CachedColumn.self,
            CachedRow.self,
            CachedCell.self,
            CachedContact.self,
            CachedOption.self,
            CachedSheetHasUpdatesToPublish.self,
            CachedSheetContactUpdatesToPublish.self,
            CachedDiscussionDTO.self,
            CachedSheetDiscussionText.self,
            CachedUser.self,
            CachedServerInfoDTO.self,
            CachedServerInfoFormatsDTO.self,
            CachedCurrency.self,
            CachedFontFamily.self,            
        ])
        
        let config = ModelConfiguration("SmartsheetOffline", schema: schema)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            InitialView()
                .onOpenURL { url in
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
                .preferredColorScheme(.light)
                .onAppear {                   
                    // The order should be as is, do not change
                    Dependencies.shared.sheetService = SheetService(modelContext: sharedModelContainer.mainContext)
                    Dependencies.shared.authenticationService.setupModelContext(modelContext: sharedModelContainer.mainContext)
                    
                    // Initializing here cause has dependency on Sheet Service
                    Dependencies.shared.serverInfoFormatParserService = ServerInfoFormatParserService(sheetService: Dependencies.shared.sheetService)
                    
//                    DependencyEnvironment.configureDependencies()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
