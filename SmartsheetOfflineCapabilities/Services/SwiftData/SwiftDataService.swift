//
//  SwiftDataProtocol.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 22/07/25.
//

import Foundation
import SwiftData

//public protocol SwiftDataProtocol {
//    var sharedModelContainer: ModelContainer { get }
//}
//
//public final class SwiftDataService: SwiftDataProtocol {
//    public var sharedModelContainer: ModelContainer = {
//        let schema = Schema([CachedSheet.self])
//        let config = ModelConfiguration("SmartsheetOffline", schema: schema)
//        return try! ModelContainer(for: schema, configurations: [config])
//    }()    
//}
//
//@Model
//final class CachedSheet {
//    @Attribute(.unique) var id: Int64
//    var name: String
//    var lastUpdated: Date
//
//    init(id: Int64, name: String, lastUpdated: Date = .now) {
//        self.id = id
//        self.name = name
//        self.lastUpdated = lastUpdated
//    }
//}
