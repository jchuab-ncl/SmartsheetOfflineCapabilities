//
//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 22/08/25.
//

import SwiftUI

struct DiscussionView: View {
    @State private var newConversationText: String = ""
    @State private var mode: AddDiscussionBottomViewMode = .addDiscussion
    @State private var commentBeingRepliedTo: DiscussionDTO? = nil
    @FocusState private var isEditorFocused: Bool
  
    @StateObject private var viewModel: DiscussionViewModel
    
    //TODO: WIP Get the discussions here, inside viewModel. This will avoid a bunch of parameters being sent
    
    private var allDiscussions: [DiscussionDTO]
    private var sheetId: Int
    private var rowDiscussions: [DiscussionDTO]
    private var rowNumber: Int = 0
    private var rowId: Int = 0
    private var columnPrimaryText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            HStack {
                ForEach(ParentTypeFilter.allCases, id: \.self) { type in
                    tabButton(for: type)
                        .padding(.bottom, 4)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            if viewModel.status == .loading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                // Comments
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        let filtered = viewModel.filterDiscussions()
                        ForEach(filtered, id: \.id) { discussion in
                            CommentView(
                                discussionDTO: discussion,
                                isReply: false,
                                onStartReply: {
                                    mode = .replyDiscussion
                                    commentBeingRepliedTo = discussion
                                }
                            )
                        }
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding()
                }
            }
                                    
            makeDiscussionBottomView()
            .padding()
            .padding(.bottom, 40)
        }
        .onTapGesture {
            isEditorFocused = false
        }
        .onAppear {
            viewModel.onAppear(sheetId: sheetId)
        }
    }
    
    // MARK: Initializer
    
    /// Initializes a new instance of `DiscussionView`.
    ///
    /// - Parameters:
    ///   - allDiscussions: An array of all discussion data transfer objects.
    ///   - sheetId: The identifier for the sheet.
    ///   - rowDiscussions: An array of discussion DTOs specific to the row.
    ///   - rowNumber: The number of the row.
    ///   - rowId: The identifier for the row.
    ///   - columnPrimaryText: The primary text for the column.
    init(
        allDiscussions: [DiscussionDTO],
        sheetId: Int,
        rowDiscussions: [DiscussionDTO],
        rowNumber: Int,
        rowId: Int,
        columnPrimaryText: String,
    ) {
        self._viewModel = .init(wrappedValue: DiscussionViewModel(rowId: rowId, sheetId: sheetId))
        self.allDiscussions = allDiscussions
        self.sheetId = sheetId
        self.rowDiscussions = rowDiscussions
        self.rowNumber = rowNumber
        self.rowId = rowId
        self.columnPrimaryText = columnPrimaryText
    }
    
    // MARK: Private methods
    
    private func tabButton(for type: ParentTypeFilter) -> some View {
        Button(action: {
            viewModel.selectedTab = type
        }) {
            Text(type.rawValue.camelCased(firstLetterUppercased: true))
                .font(.subheadline.bold())
                .foregroundColor(viewModel.selectedTab == type ? .blue : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(viewModel.selectedTab == type ? Color.blue.opacity(0.1) : .clear)
                .cornerRadius(8)
        }
    }
    
    private func makeDiscussionBottomView() -> some View {
        VStack {
            Divider()
                .padding(.vertical, 12)

            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.orange)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Row \(rowNumber)")
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule().fill(Color.gray.opacity(0.15))
                            )
                        
                        if columnPrimaryText.isNotEmpty {
                            Text(columnPrimaryText)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if mode == .replyDiscussion, let title = commentBeingRepliedTo?.title {
                        (
                            Text("Replying to: ")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            + Text(title)
                                .font(.caption)
                                .foregroundColor(.primary)
                        )
                        .padding(.horizontal, 8)
                    }

                    // Editor box with placeholder and trailing icons
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.25))
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.06)))

                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                if newConversationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(mode == .addDiscussion ? "Add your comment here..." : "Add your reply here...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .font(.subheadline)
                                }
                                TextEditor(text: $newConversationText)
                                    .focused($isEditorFocused)
                                    .padding(.horizontal, 2)
                                    .scrollContentBackground(.hidden)
                                    .font(.subheadline)
                            }

                            HStack(spacing: 16) {
                                if mode == .replyDiscussion {
                                    Button(action: {
                                        newConversationText = ""
                                        mode = .addDiscussion
                                    }) {
                                        Text("Cancel")
                                            .font(.subheadline.bold())
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(Capsule().fill(Color.red.opacity(0.15)))
                                            .foregroundStyle(.red)
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    if mode == .addDiscussion {
                                        //TODO: WIP get the rowId or sheetID
                                        viewModel.post(parentId: sheetId, value: newConversationText)
                                        newConversationText = ""
                                    } else if mode == .replyDiscussion {
                                        
                                    }
                                }) {
                                    Text("Post")
                                        .font(.subheadline.bold())
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Capsule().fill(Color.blue.opacity(0.15)))
                                        .foregroundColor(newConversationText.isEmpty ? .gray : .blue)
                                }
                                .disabled(newConversationText.isEmpty)
                            }
                        }
                        .padding(8)
                    }
                }
            }

            Spacer()
        }
        .background(.white)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44, maxHeight: 44)
    }
}

enum AddDiscussionBottomViewMode: String {
    case replyDiscussion
    case addDiscussion
}

enum ParentTypeFilter: String, CaseIterable {
    case row = "ROW"
    case sheet = "SHEET"
    case all = "All"
}

struct CommentView: View {
    var cachedSheetDiscussionToPublishDTO: CachedSheetDiscussionToPublishDTO?
    var discussionDTO: DiscussionDTO?
    var isReply: Bool
    var onStartReply: (() -> Void)? = nil
        
    private var comment: CommentDTO? {
        discussionDTO?.comments?.first
    }
    
    private var title: String {
        discussionDTO?.title ?? cachedSheetDiscussionToPublishDTO?.comment.text ?? ""
    }
    
    private var replyComments: [CommentDTO]? {
        discussionDTO?.comments
    }
    
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
                    Text(comment?.createdBy?.name ?? cachedSheetDiscussionToPublishDTO?.userName ?? "NOT FOUND")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(comment?.createdAt?.asFormattedDate(
                        inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ",
                        outputFormat: "MM/dd/yy")
                    ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text((isReply ? comment?.text : title) ?? "")
                    .font(.body)
                
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
        var name = comment?.createdBy?.name ?? ""
        
        if name.isEmpty {
            name = "\(cachedSheetDiscussionToPublishDTO?.firstNameUser ?? "") \(cachedSheetDiscussionToPublishDTO?.lastNameUser ?? "")"
        }
        
        return name.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined()
    }
}

struct ReplyCommentView: View {
    var comment: CommentDTO
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.orange)
                .frame(width: 24, height: 24)
                .overlay(Text(initials(from: comment.createdBy?.name ?? ""))
                            .font(.caption.bold())
                            .foregroundColor(.white))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.createdBy?.name ?? "")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(comment.createdAt?.asFormattedDate(
                            inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ",
                            outputFormat: "MM/dd/yy") ?? ""
                         )
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(comment.text)
                    .font(.body)
            }
        }
    }
    
    private func initials(from name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined()
    }
}
