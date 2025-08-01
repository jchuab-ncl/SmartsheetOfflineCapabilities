//
//  SheetDetailViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

import Foundation
import SwiftData

@MainActor
final class SheetDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var status: ProgressStatus = .initial
    @Published var sheetContentDTO: SheetContentDTO?
        
    // MARK: Private Properties
    
    private let sheetService: SheetServiceProtocol
    
    // MARK: - Initializers

    /// Initializes the view model with a given sheet service.
    /// - Parameter modelContext: The SwiftData model context used by the view model to access stored data.
    init(modelContext: ModelContext) {
        self.sheetService = SheetService(modelContext: modelContext)
    }
    
    // MARK: - Public Methods
    
    func loadSheetContent(sheetId: Int) {
        Task {
            status = .loading
            
            do {
                sheetContentDTO = try await sheetService.getSheetContent(sheetId: sheetId)
                status = .success
            } catch {
                status = .error
            }
        }
    }
}
