//
//  CommentView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 02/09/25.
//

import SwiftUI

struct CommentView: View {
    
    @StateObject var viewModel = CommentViewModel()
    
    // MARK: Public properties
    
//    var cachedSheetDiscussionToPublishDTO: CachedSheetDiscussionToPublishDTO?
    var discussionDTO: DiscussionDTO
    var isReply: Bool
    var onStartReply: (() -> Void)? = nil
    
    // MARK: Private properties
        
    private var comment: CommentDTO? {
        discussionDTO.comments?.first
    }
    
    private var title: String {
        discussionDTO.title ?? "" //?? cachedSheetDiscussionToPublishDTO?.comment.text ?? ""
    }
    
    private var replyComments: [CommentDTO]? {
        discussionDTO.comments
    }
    
    // MARK: The view body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.orange)
                .frame(width: 32, height: 32)
                .overlay(Text(initials())
                            .font(.caption.bold())
                            .foregroundColor(.white))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment?.createdBy?.name ?? "NOT FOUND" /*?? cachedSheetDiscussionToPublishDTO?.userName ?? "NOT FOUND"*/)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(comment?.createdAt?.asFormattedDate(
                        inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ",
                        outputFormat: "MM/dd/yy")
                    ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                HStack {
                    Text((isReply ? comment?.text : title) ?? "")
                        .font(.body)
                    
                    Spacer()
                    
                    if viewModel.shouldShowContextMenu(discussionDTO: discussionDTO) {
                        Menu {
                            HStack {
                                Button("Remove", action: {
                                    viewModel.removeComment(discussionDTO: discussionDTO)
                                })
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .contentShape(Rectangle())
                                .padding(.all, 8)
                                .foregroundStyle(Color.gray)
                        }
                    }
                }
                                                
                ForEach(replyComments?.dropFirst() ?? []) { replyComment in
                    ReplyCommentView(comment: replyComment)
                        .padding(.vertical, 16)
                }
                
                Button(action: {
                    onStartReply?()
                }) {
                    Text("↩︎ Reply")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func initials() -> String {
        let name = comment?.createdBy?.name ?? ""
        
//        if name.isEmpty {
//            name = "\(cachedSheetDiscussionToPublishDTO?.firstNameUser ?? "") \(cachedSheetDiscussionToPublishDTO?.lastNameUser ?? "")"
//        }
        
        return name.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined()
    }
}
