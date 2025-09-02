//
//  DiscussionViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 28/08/25.
//

import Combine
import SwiftUI

final class DiscussionViewModel: ObservableObject {
//    @Published var cachedSheetDiscussionToPublishDTOInMemory: [CachedSheetDiscussionToPublishDTO] = []
    @Published var selectedTab: ParentTypeFilter = .row
    @Published var sheetContentDTO: SheetContentDTO?
    /// This variable contain the DiscussionDTO that is only stored locally, and was not synced yet
    @Published var discussionsToPublish: [DiscussionDTO] = []
    @Published var status: ProgressStatus = .initial
    
    // MARK: Private Properties
    
    private let authenticationService: AuthenticationServiceProtocol
    private let httpApiClient: HTTPApiClientProtocol
    private let sheetService: SheetServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var rowId: Int
    private var sheetId: Int
    
    // MARK: - Initializers

    /// Initializes the `SelectFileViewModel`, setting up dependencies and bindings.
    ///
    /// - Parameters:
    ///  - rowId:
    ///  - sheetId:
    ///  - authenticationService: The service used to handle authentication logic. Defaults to the shared dependency.
    ///  - sheetService: The service used to fetch sheets and updates. Defaults to `Dependencies.shared.sheetService`.
    init(
        rowId: Int,
        sheetId: Int,
        authenticationService: AuthenticationServiceProtocol = Dependencies.shared.authenticationService,
        httpApiClient: HTTPApiClientProtocol = Dependencies.shared.httpApiClient,
        sheetService: SheetServiceProtocol = Dependencies.shared.sheetService
    ) {
        self.rowId = rowId
        self.sheetId = sheetId
        self.authenticationService = authenticationService
        self.httpApiClient = httpApiClient
        self.sheetService = sheetService
        
//        sheetService.sheetDiscussionToPublishDTOMemoryRepo
//            .receive(on: DispatchQueue.main)
//            .removeDuplicates()
//            .sink(receiveValue: { [weak self] result in
//                self?.cachedSheetDiscussionToPublishDTOInMemory.append(contentsOf: result)
//            })
//            .store(in: &cancellables)
        
        sheetService.discussionsToPublishStorageRepo
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] result in
                self?.discussionsToPublish = result.map { .init(from: $0) }
            })
            .store(in: &cancellables)
    }
    
    // MARK: Public methods
    
    @MainActor
    func onAppear(sheetId: Int) {
        Task {
            status = .loading
            do {
                sheetContentDTO = try await sheetService.getSheetContent(sheetId: sheetId)
                discussionsToPublish = try await sheetService.getDiscussionToPublishForSheet(sheetId: sheetId)

                status = .success
            } catch {
                status = .error
            }
        }
    }
    
    func post(parentId: Int, value: String) {
        Task {
        //TODO: Add status
            let parentId = selectedTab == .row ? rowId : sheetId
            let parentType = selectedTab == .row ? CachedSheetDiscussionToPublishDTOType.row : CachedSheetDiscussionToPublishDTOType.sheet
            
            //TODO: Remove that and use only the storage one
            sheetService.addDiscussionToPublishInMemoryRepo(sheet:
                .init(
                    id: UUID().hashValue,
                    dateTime: Date(),
                    sheetId: sheetId,
                    parentId: parentId,
                    parentType: parentType,
                    comment: .init(text: value),
                    firstNameUser: authenticationService.cachedUserDTO?.firstName ?? "",
                    lastNameUser: authenticationService.cachedUserDTO?.lastName ?? ""
                )
            )
            
            if await httpApiClient.isInternetAvailable() {
                //TODO: Save comments online
            } else {
                //TODO: Save comments offline
                await sheetService.commitSheetDiscussionToStorage(parentId: parentId)
            }
        }
    }
        
    func filterDiscussions() -> [DiscussionDTO] {
//        let discussionsToPublish: [DiscussionDTO] = cachedSheetDiscussionToPublishDTOInMemory .map { .init(from: $0) }
        let allDiscussions: [DiscussionDTO] = self.sheetContentDTO?.discussions ?? []
        let rowDiscussions: [DiscussionDTO] = self.sheetContentDTO?.discussionsForRow(rowId) ?? []
        
        var result: [DiscussionDTO] = []
        
        switch selectedTab {
        case .all:
            result.append(contentsOf: allDiscussions)
            result.append(contentsOf: discussionsToPublish)
            return result.sorted { createdAtDate(from: $0) < createdAtDate(from: $1) }
        
        case .row:
            result.append(contentsOf: rowDiscussions)
            result.append(contentsOf: discussionsToPublish)
            return result
                .filter { $0.parentType == ParentTypeFilter.row.rawValue }
                .sorted { createdAtDate(from: $0) < createdAtDate(from: $1) }
            
        case .sheet:
            result.append(contentsOf: allDiscussions)
            result.append(contentsOf: discussionsToPublish)
            return result
                .filter { $0.parentType == ParentTypeFilter.sheet.rawValue }
                .sorted { createdAtDate(from: $0) < createdAtDate(from: $1) }
        }
    }
    
    private func createdAtDate(from discussion: DiscussionDTO) -> Date {
        discussion.comments?.first?.createdAt?.asDate(inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ") ?? .distantPast
    }
}

