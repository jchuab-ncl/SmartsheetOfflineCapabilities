//
//  SheetListViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 11/06/25.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class SheetListViewModel: ObservableObject {            
    // MARK: - Published Properties

    @Published var isInternetAvailable: Bool = true
    @Published var sheetsList: [CachedSheetDTO] = []
    @Published var sheetsContentList: [SheetContentDTO] = []
    @Published var sheetsListHasUpdatesToPublish: [CachedSheetHasUpdatesToPublishDTO] = []
    @Published var status: ProgressStatus = .initial
    @Published var statusSync: [Int: ProgressStatus] = [:]
    
    // MARK: Private Properties
    
    private let sheetService: SheetServiceProtocol
    private var networkMonitor: NetworkMonitor = NetworkMonitor()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializers

    /// Initializes the `SelectFileViewModel`, setting up dependencies and bindings.
    ///
    /// - Parameter sheetService: The service used to fetch sheets and updates. Defaults to `Dependencies.shared.sheetService`.
    ///
    /// This initializer sets up:
    /// - A `NetworkMonitor` to observe real-time internet connectivity updates, binding the result to `isInternetAvailable`.
    /// - A subscription to `sheetService.resultSheetHasUpdatesToPublishDTO`, updating the local `sheetsListHasUpdatesToPublish` whenever changes are published.
    init(
        sheetService: SheetServiceProtocol = Dependencies.shared.sheetService
    ) {
        self.sheetService = sheetService
        
        // Bind published internet status
        networkMonitor.$isConnected
           .receive(on: DispatchQueue.main)
           .assign(to: \.isInternetAvailable, on: self)
           .store(in: &cancellables)
                
        sheetService.sheetWithUpdatesToPublishStorageRepo
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] result in
                self?.sheetsListHasUpdatesToPublish = result
            })
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func loadSheets() {
        Task {
            status = .loading
            
            do {
                self.sheetsList.removeAll()
                self.sheetsList = try await sheetService.getSheetList()
                
                for sheet in self.sheetsList {
                    let result = try await sheetService.getSheetContent(sheetId: sheet.id)
                    sheetsContentList.append(result)
                }
                
                try await sheetService.getSheetListHasUpdatesToPublish()
                
                status = .success
            } catch {
                status = .error
            }
        }
    }
    
    func syncData(sheetId: Int) {
        Task {
            statusSync[sheetId] = .loading
            
            do {
    //            // TODO: Remove
    //            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    //                self.sheetsListHasUpdatesToPublish = []
    //                self.statusSync[sheetId] = .success
    //            }
                try await sheetService.pushChangesToApi(sheetId: sheetId)
                self.statusSync[sheetId] = .success
//                self.sheetsList = try await sheetService.getSheetList()
            } catch {
                statusSync[sheetId] = .error
            }
        }
    }
}
