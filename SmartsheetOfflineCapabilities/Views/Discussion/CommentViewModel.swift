//
//  CommentViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 02/09/25.
//

import SwiftUI

final class CommentViewModel: ObservableObject {
    
    // MARK: Private properties
    
    private let authenticationService: AuthenticationServiceProtocol
    private let logService: LogServiceProtocol
    private let sheetService: SheetServiceProtocol
    
    // MARK: Initializer
    
    /// Initializes a new `CommentViewModel`.
    ///
    /// This view model is responsible for handling comment-related UI logic,
    /// including permission checks and local comment removal before sync.
    ///
    /// - Parameters:
    ///   - authenticationService: Service used to access the currently authenticated user.
    ///   - logService: Logging service used to record diagnostics and errors.
    ///   - sheetService: Service responsible for managing sheet discussions and persistence.
    init(
        authenticationService: AuthenticationServiceProtocol = Dependencies.shared.authenticationService,
        logService: LogServiceProtocol = Dependencies.shared.logService,
        sheetService: SheetServiceProtocol = Dependencies.shared.sheetService
    ) {
        self.authenticationService = authenticationService
        self.logService = logService
        self.sheetService = sheetService
    }
    
    // MARK: Public methods
    
    func shouldShowContextMenu(
        discussionDTO: DiscussionDTO
    ) -> Bool {

        guard let loggedUserFirstName = authenticationService.cachedUserDTO?.firstName,
              let loggedUserLastName = authenticationService.cachedUserDTO?.lastName,
              let userName = discussionDTO.createdBy?.name
        else {
            return false
        }
        
        return loggedUserFirstName + " " + loggedUserLastName == userName && discussionDTO.publishPending == true
    }
    
    func removeComment(discussionDTO: DiscussionDTO) {
        //TODO: Add status / loading animation
        
        Task {
            do {
                try await sheetService.removeDiscussionToPublishFromStorage(discussionDTO: discussionDTO)
            } catch {
                logService.add(
                    text: "Error removing comment: \(error.localizedDescription)",
                    type: .error,
                    context: String(describing: type(of: self))
                )
            }
        }
    }
        
}
