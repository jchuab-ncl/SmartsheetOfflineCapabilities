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
    private let sheetService: SheetServiceProtocol
    
    // MARK: Initializer
    
    init (
        authenticationService: AuthenticationServiceProtocol = Dependencies.shared.authenticationService,
        sheetService: SheetServiceProtocol = Dependencies.shared.sheetService
    ) {
        self.authenticationService = authenticationService
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
                print("Error removing comment: \(error.localizedDescription)")
            }
        }
    }
        
}
