//
//  EditableCellViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 20/09/25.
//

//import Combine
import Foundation
import SwiftData

@MainActor
final class EditableCellViewModel: ObservableObject {
    
    // MARK: Published Properties
    
    @Published var status: ProgressStatus = .initial
    
    // MARK: Private Properties    
    
    private let sheetService: SheetServiceProtocol
    
    // MARK: Initializers
    
    /// Initializes the `EditableCellViewModel`
    ///
    /// - Parameter sheetService: The service used to fetch sheets and updates. Defaults to `Dependencies.shared.sheetService`.
    init(sheetService: SheetServiceProtocol = Dependencies.shared.sheetService) {
        self.sheetService = sheetService
    }
    
    // MARK: Public methods
    
    public func discardLocalChanges(conflict: Conflict) {
        Task {
            status = .loading
            
            do {
                try await sheetService.removeSheetHasUpdatesToPublish(
                    sheetId: conflict.sheetId,
                    rowId: conflict.rowId,
                    columnId: conflict.columnId
                )
                
                try await sheetService.checkForConflicts(sheetId: conflict.sheetId)
            } catch {
                status = .error
            }
        }
    }
    
    public func formatData(value: String, columnType: ColumnType) -> String {
        // Formatting data
        var formatedValue = ""
//        var selectedContactsArray: [CachedSheetContactUpdatesToPublishDTO] = []
        
        switch columnType {
        case .abstractDateTime, .contactList, .multiContactList, .checkbox, .duration, .predecessor, .textNumber:
            formatedValue = value
            
            //WIP: Conflict for contacts
            
            //                    if !selectedContacts.isEmpty {
            //                        selectedContactsArray = selectedContacts.map({
            //                            .init(
            //                                sheetId: conflict.sheetId,
            //                                rowId: conflict.rowId,
            //                                columnId: conflict.columnId,
            //                                name: $0.name,
            //                                email: $0.email
            //                            ) })
            //                    }
            
        case .date:
            formatedValue = value.asFormattedDate(inputFormat: "yyyy-MM-dd", outputFormat: "MM/dd/yy")
        case .dateTime:
            formatedValue = value.asFormattedDate(inputFormat: "MM/dd/yy h:mm a", outputFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
        case .multiPicklist, .picklist:
            formatedValue = value
        }
            
        return formatedValue
    }
}
