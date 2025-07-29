//
//  SwiftDataProtocol.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 22/07/25.
//

import Foundation
import SwiftData
 
public protocol SwiftDataProtocol {
    var modelContext: ModelContext { get }
}

public final class SwiftDataService: SwiftDataProtocol {
    public let sharedModelContainer: ModelContainer
    public var modelContext: ModelContext

    public init() {
        let schema = Schema([CachedSheet.self, CachedSheetContent.self])
        let config = ModelConfiguration("SmartsheetOffline", schema: schema)
        self.sharedModelContainer = try! ModelContainer(for: schema, configurations: [config])
        self.modelContext = ModelContext(self.sharedModelContainer)
    }
}
