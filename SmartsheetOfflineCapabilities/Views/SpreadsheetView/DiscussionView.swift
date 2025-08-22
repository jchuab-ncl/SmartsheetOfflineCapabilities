//
//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 22/08/25.
//

import SwiftUI

struct DiscussionView: View {
    @State private var selectedTab: ParentTypeFilter = .row
    
    var allDiscussions: [DiscussionDTO]
    var rowDiscussions: [DiscussionDTO]

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
}

enum ParentTypeFilter: String, CaseIterable {
    case row = "ROW"
    case sheet = "SHEET"
    case all = "All"
}

struct CommentView: View {
    var comment: CommentDTO?
    var replyComments: [CommentDTO]?
    var title: String
    var isReply: Bool
    
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
                        outputFormat: "MM/dd/yy hh:mm:ss")
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
                    // Future reply action
                }) {
                    Text("↩︎ Reply")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
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
                            outputFormat: "MM/dd/yy hh:mm:ss") ?? ""
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
