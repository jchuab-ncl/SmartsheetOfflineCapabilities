//
//  SheetDetailViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

import Foundation

@MainActor
final class SheetDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var status: ProgressStatus = .initial
    @Published var sheetDetailResponse: SheetDetailResponse?
        
    // MARK: Private Properties
    
    private let sheetService: SheetServiceProtocol
    
    // MARK: - Initializers

    /// Initializes the view model with a given sheet service.
    /// - Parameter sheetService: The service used to retrieve sheet details. Defaults to a concrete implementation.
    init(sheetService: SheetServiceProtocol = Dependencies.shared.sheetService) {
        self.sheetService = sheetService
    }
    
    // MARK: - Public Methods
    
    func loadSheetContent(sheetId: Int) {
        Task {
            status = .loading
            
            do {
                sheetDetailResponse = try await sheetService.getSheet(sheetId: sheetId)
                status = .success
            } catch {
                status = .error
            }
        }
    }
}
