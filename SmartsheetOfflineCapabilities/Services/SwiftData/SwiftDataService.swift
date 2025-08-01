//
//  SwiftDataProtocol.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 22/07/25.
//

import Foundation
import SwiftData
 
//public protocol SwiftDataProtocol {
//    var modelContext: ModelContext { get }
//}
//
//public final class SwiftDataService: SwiftDataProtocol {
//    private let sharedModelContainer: ModelContainer
//    public var modelContext: ModelContext
//
//    public init() {
//        
//        // All models should be included here
//        let schema = Schema([
//            CachedSheet.self,
//            CachedSheetContent.self,
//            CachedColumn.self,
//            CachedRow.self,
//            CachedCell.self,
//            CachedContact.self,
//            CachedOption.self
//        ])
//        
//        let config = ModelConfiguration("SmartsheetOffline", schema: schema, isStoredInMemoryOnly: false)
//        self.sharedModelContainer = try! ModelContainer(for: schema, configurations: [config])
//        self.modelContext = ModelContext(self.sharedModelContainer)
//    }
//}
