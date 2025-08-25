//
//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 22/08/25.
//

import SwiftUI

struct DiscussionView: View {
    @State private var selectedTab: ParentTypeFilter = .row
    @State private var newConversationText: String = ""
    
    var allDiscussions: [DiscussionDTO]
    var rowDiscussions: [DiscussionDTO]
    var rowIndex: Int = 0
    var rowTextPreview: String = "Lorem ipsum lorem lorem lorem bla lor ip lor bra will"

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
            
            // Comments
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    let filtered = filterDiscussions()
                    ForEach(filtered, id: \.id) { discussion in
                        CommentView(
                            comment: discussion.comments?.first,
                            replyComments: discussion.comments,
                            title: discussion.title ?? "",
                            isReply: false
                        )
                    }
                }
                .padding()
            }
            
            addDiscussionBottomView()
                .padding()
                .padding(.bottom, 40)
        }
    }
    
    private func tabButton(for type: ParentTypeFilter) -> some View {
        Button(action: {
            selectedTab = type
        }) {
            Text(type.rawValue.camelCased(firstLetterUppercased: true))
                .font(.subheadline.bold())
                .foregroundColor(selectedTab == type ? .blue : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(selectedTab == type ? Color.blue.opacity(0.1) : .clear)
                .cornerRadius(8)
        }
    }
    
    private func filterDiscussions() -> [DiscussionDTO] {
        func createdAtDate(from discussion: DiscussionDTO) -> Date {
            discussion.comments?.first?.createdAt?.asDate(inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ") ?? .distantPast
        }
        
        switch selectedTab {
        case .all:
            return allDiscussions.sorted { createdAtDate(from: $0) < createdAtDate(from: $1) }
        case .row:
            return rowDiscussions.sorted { createdAtDate(from: $0) < createdAtDate(from: $1) }
        case .sheet:
            return allDiscussions
                .filter { $0.parentType == ParentTypeFilter.sheet.rawValue }
                .sorted { createdAtDate(from: $0) < createdAtDate(from: $1) }
        }
    }
    
    @ViewBuilder
    private func addDiscussionBottomView() -> some View {
        VStack {
            Divider()
                .padding(.vertical, 12)
            
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.orange)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("JC")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    // Context pill (static for layout – wire later)
                    HStack(spacing: 8) {
                        Text("Row \(rowIndex)")
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule().fill(Color.gray.opacity(0.15))
                            )
                        Text(rowTextPreview)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }

                    // Editor box with placeholder and trailing icons
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.25))
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.06)))

                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                if newConversationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Add your comment here...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .font(.subheadline)
                                }
                                TextEditor(text: $newConversationText)
                                    .padding(.horizontal, 2)
                                    .scrollContentBackground(.hidden)
                                    .font(.subheadline)
                            }

                            // Action row (icons only – no actions yet)
                            HStack(spacing: 16) {

                                Spacer()
                                // Disabled post button for layout only
                                Button(action: {}) {
                                    Text("Post")
                                        .font(.subheadline.bold())
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Capsule().fill(Color.blue.opacity(0.15)))
                                }
                                .disabled(newConversationText.isEmpty)
                            }
                            .foregroundColor(.secondary)
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

enum ParentTypeFilter: String, CaseIterable {
    case row = "ROW"
    case sheet = "SHEET"
    case all = "All"
}

struct CommentView: View {
    @State private var isReplySheetPresented: Bool = false
    @State private var draftReply: String = ""

    var comment: CommentDTO?
    var replyComments: [CommentDTO]?
    var title: String
    var isReply: Bool
    var onSubmitReply: ((String) -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.orange)
                .frame(width: 32, height: 32)
                .overlay(Text(initials(from: comment?.createdBy?.name ?? ""))
                            .font(.caption.bold())
                            .foregroundColor(.white))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment?.createdBy?.name ?? "NOT FOUND")
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
                    isReplySheetPresented = true
                }) {
                    Text("↩︎ Reply")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
                .sheet(isPresented: $isReplySheetPresented) {
                    NavigationStack {
                        makeReplyView()
                    }
                }
            }
        }
    }
    
    private func makeReplyView() -> some View {
        VStack {
            Text("Reply to \(comment?.createdBy?.name ?? title)")
                .font(.headline)
                .padding()
            
            TextEditor(text: $draftReply)
                .padding()
            
            HStack(spacing: 40) {
                Button("Cancel") {
                    isReplySheetPresented = false
                    draftReply = ""
                }
                .foregroundColor(.red)

                Button("Done") {
                    // Commit the staged value and close
                    let trimmed = draftReply.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onSubmitReply?(trimmed) }
                    isReplySheetPresented = false
                    draftReply = ""
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func initials(from name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined()
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
