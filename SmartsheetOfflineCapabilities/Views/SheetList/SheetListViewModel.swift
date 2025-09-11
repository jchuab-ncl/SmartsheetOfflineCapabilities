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
    @Published var sheetsDiscussionsToPublish: [CachedSheetDiscussionToPublishDTO] = []
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
//           .assign(to: \.isInternetAvailable, on: self)
           .sink(receiveValue: { [weak self] result in
               self?.isInternetAvailable = result
           })
           .store(in: &cancellables)
                
        sheetService.sheetWithUpdatesToPublishStorageRepo
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] result in
                self?.sheetsListHasUpdatesToPublish = result
            })
            .store(in: &cancellables)
        
        sheetService.discussionsToPublishStorageRepo
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] result in
                self?.sheetsDiscussionsToPublish = result
            })
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    
    func shouldShowSyncButton(sheetId: Int) -> Bool {
        guard isInternetAvailable else {
            return false
        }
        
        let contentToPublish = sheetsListHasUpdatesToPublish.first(where: { $0.sheetId == sheetId })
        //TODO: Compare sheetId
        let discussionsToPublish = sheetsDiscussionsToPublish.first(where: { $0.sheetId == sheetId })
        
        return (contentToPublish != nil || discussionsToPublish != nil)
    }

    func loadSheets() {
        Task {
            status = .loading
            
            do {
                //TODO: Remove ???
//                guard sheetsList.isEmpty else { return }
                
                self.sheetsList.removeAll()
                self.sheetsList = try await sheetService.getSheetList()
                
                for sheet in self.sheetsList {
                    let sheetContentResult = try await sheetService.getSheetContent(sheetId: sheet.id)
                    sheetsContentList.append(sheetContentResult)
                    
                    _ = try await sheetService.getSheetListHasUpdatesToPublish()
//                    let discussionResult = try await sheetService.getDiscussionForSheet(sheetId: sheet.id)
//                    discussionList.append(contentsOf: discussionResult)
                }
                
                try await sheetService.getServerInfo()
                
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
                try await sheetService.pushSheetContentToApi(sheetId: sheetId)
                try await sheetService.pushDiscussionsToApi(sheetId: sheetId)
                
                // After pushing the changes we can download the last changes from the API
                // TODO: This will change once we implement the conflict solving feature
                _ = try await sheetService.getSheetContentOnline(sheetId: sheetId)
                self.statusSync[sheetId] = .success
            } catch {
                statusSync[sheetId] = .error
            }
        }
    }
}
