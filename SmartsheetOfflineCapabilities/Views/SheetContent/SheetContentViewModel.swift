//
//  SheetContentViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class SheetContentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var status: ProgressStatus = .initial
    @Published var sheetContentDTO: SheetContentDTO = .empty
    @Published var showSaveButton = false
    @Published var cachedSheetHasUpdatesToPublishDTO: [CachedSheetHasUpdatesToPublishDTO] = []
    @Published var scrollToRow: Int?
        
    // MARK: Private Properties
    
    private let sheetService: SheetServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializers
    
    /// Initializes a new instance of `SheetContentViewModel`.
    ///
    /// This initializer sets up the `sheetService` dependency and subscribes to the
    /// `resultSheetHasUpdatesToPublishDTO` publisher to automatically determine if
    /// the current sheet has updates pending publication. If the current sheet is found
    /// in the updates list, `showSaveButton` is set to `true`.
    ///
    /// - Parameter sheetService: A service conforming to `SheetServiceProtocol`, used for
    ///   loading and tracking sheet content. Defaults to `Dependencies.shared.sheetService`.
    init(sheetService: SheetServiceProtocol = Dependencies.shared.sheetService) {
        
        self.sheetService = sheetService
        
        sheetService.sheetWithUpdatesToPublishMemoryRepo
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] result in
                self?.showSaveButton = result.first(where: { $0.sheetId == self?.sheetContentDTO.id }) != nil
            })
            .store(in: &cancellables)
        
        sheetService.sheetWithUpdatesToPublishStorageRepo
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] result in
                self?.cachedSheetHasUpdatesToPublishDTO = result
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func addEmptyRow(sheetId: Int) {
        saveSheetContent(sheetId: sheetId) {
            let newCells = self.sheetContentDTO.columns.map {
                CellDTO(
                    columnId: $0.id,
                    conditionalFormat: nil,
                    value: "",
                    displayValue: "",
                    format: nil
                )
            }
            let rowNumber = self.sheetContentDTO.rows.count + 1
            let newRow = RowDTO(id: -rowNumber, dateTime: Date(), rowNumber: rowNumber, cells: newCells)
            self.sheetContentDTO.rows.append(newRow)
            self.scrollToRow = self.sheetContentDTO.rows.count - 1
            self.objectWillChange.send()
        }
    }
    
    func loadSheetContent(sheetId: Int) {
        Task {
            status = .loading
            
            do {
                sheetContentDTO = try await sheetService.getSheetContent(sheetId: sheetId)
                
                //TODO: Load discussions
                
                try await sheetService.getSheetListHasUpdatesToPublish()
                
                status = .success
            } catch {
                status = .error
            }
        }
    }
    
    func saveSheetContent(sheetId: Int, completion: @escaping () -> Void) {
        Task {
            status = .loading
            do {
                try await sheetService.commitMemoryToStorage(sheetId: sheetId)
                //TODO: Dismiss the screen
                status = .success
                completion()
            } catch {
                status = .error
            }
        }
    }
    
    func removeSheetContentChanges(sheetId: Int) {
        Task {
            status = .loading
            
            do {
                try await sheetService.removeSheetHasUpdatesToPublish(sheetId: sheetId, rowId: nil, columnId: nil)
                try await sheetService.getSheetListHasUpdatesToPublish()
                
                status = .success
            } catch {
                status = .error
            }
        }
    }
}
