//
//  SelectFileViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 11/06/25.
//

import Combine
import Foundation

@MainActor
final class SelectFileViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var sheetsList: [CachedSheet] = []
    @Published var status: ProgressStatus = .initial
    
    // MARK: Private Properties
    
    private let sheetService: SheetServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers

    /// Initializes the view model with a given sheet service.
    /// - Parameter sheetService: The service used to fetch sheet data. Defaults to a concrete implementation.
    init(sheetService: SheetServiceProtocol = SheetService()) {
        self.sheetService = sheetService
    }

    // MARK: - Public Methods

    func loadSheets() {
        Task {
            status = .loading
            
            do {
                let result = try await sheetService.getSheets()
    
                let files = result.map {
                    CachedSheet(
                        id: $0.id,
                        modifiedAt: $0.modifiedAt,
                        name: $0.name
                    )
                    
//                    SheetFile(
//                        id: Int64($0.id),
//                        name: $0.name,
//                        accessLevel: $0.accessLevel,
//                        permalink: $0.permalink,
//                        createdAt: ISO8601DateFormatter().date(from: $0.createdAt) ?? .now,
//                        modifiedAt: ISO8601DateFormatter().date(from: $0.modifiedAt) ?? .now
//                    )
                }.sorted(by: { $0.name < $1.name })
    
                self.sheetsList = files
                
                status = .success
            } catch {
                status = .error
            }
        }
    }
}
