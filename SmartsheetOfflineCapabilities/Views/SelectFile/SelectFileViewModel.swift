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

    @Published var sheetsList: [SheetFile] = []
    @Published var status: ProgressStatus = .initial
//    @Published var message: String?
//    @Published var messageIcon: String?
    
    // MARK: Private Properties
    
    private let sheetService: SheetServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(sheetService: SheetServiceProtocol = SheetService()) {
        self.sheetService = sheetService
        
//        sheetService.resultType
//            .receive(on: DispatchQueue.main)
//            .removeDuplicates()
//            .sink(receiveValue: { [weak self] result in
//                self?.status = result.status
//                
//                let files = result.sheetList?.data.map {
//                    SheetFile(
//                        id: Int64($0.id),
//                        name: $0.name,
//                        accessLevel: $0.accessLevel,
//                        permalink: $0.permalink,
//                        createdAt: ISO8601DateFormatter().date(from: $0.createdAt) ?? .now,
//                        modifiedAt: ISO8601DateFormatter().date(from: $0.modifiedAt) ?? .now
//                    )
//                }.sorted(by: { $0.name < $1.name }) ?? []
//
//                self?.sheetsList = files
//                self?.message = "\(result.status.icon) \(result.message.description)"
//            })
//            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func loadSheets() {
        Task {
            status = .loading
            
            do {
                let result = try await sheetService.listSheet()
    
                let files = result.data.map {
                    SheetFile(
                        id: Int64($0.id),
                        name: $0.name,
                        accessLevel: $0.accessLevel,
                        permalink: $0.permalink,
                        createdAt: ISO8601DateFormatter().date(from: $0.createdAt) ?? .now,
                        modifiedAt: ISO8601DateFormatter().date(from: $0.modifiedAt) ?? .now
                    )
                }.sorted(by: { $0.name < $1.name })
    
                self.sheetsList = files
                
                status = .success
            } catch {
                status = .error
            }
        }
    }
}
