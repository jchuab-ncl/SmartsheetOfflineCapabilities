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

    @Published var sheetsList: [CachedSheetDTO] = []
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
                self.sheetsList.removeAll()
                self.sheetsList = try await sheetService.getSheetList()
                status = .success
            } catch {
                status = .error
            }
        }
    }
}
