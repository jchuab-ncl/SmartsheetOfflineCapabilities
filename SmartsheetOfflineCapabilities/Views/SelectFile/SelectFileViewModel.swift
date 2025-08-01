//
//  SelectFileViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 11/06/25.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class SelectFileViewModel: ObservableObject {            
    // MARK: - Published Properties

    @Published var sheetsList: [CachedSheetDTO] = []
    @Published var status: ProgressStatus = .initial
    
    // MARK: Private Properties
    
    private let sheetService: SheetServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers

    /// Initializes the view model with a model context used to create the sheet service.
    /// - Parameter modelContext: The SwiftData model context used to initialize the sheet service.
    init(modelContext: ModelContext) {
        self.sheetService = SheetService(modelContext: modelContext)
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
