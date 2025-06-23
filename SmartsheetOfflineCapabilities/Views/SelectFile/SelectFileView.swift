//
//  SelectFileView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 11/06/25.
//


import SwiftUI

struct SheetFile: Identifiable, Hashable {
    let id: Int64
    let name: String
    let accessLevel: String
    let permalink: String
    let createdAt: Date
    let modifiedAt: Date
}

struct SelectFileView: View {
    
    @State private var selectedFile: SheetFile?
    @State private var searchText = ""
    
    var mockFiles: [SheetFile] {
        [
            SheetFile(
                id: 6141831453927300,
                name: "My first sheet",
                accessLevel: "ADMIN",
                permalink: "https://app.smartsheet.com/b/home?lx=8enlO7GkdYSz-cHHVus33A",
                createdAt: ISO8601DateFormatter().date(from: "2023-09-25T17:38:02Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2023-09-25T17:38:09Z")!
            ),
            SheetFile(
                id: 6141831453927301,
                name: "Project Plan",
                accessLevel: "EDITOR",
                permalink: "https://app.smartsheet.com/b/home?lx=abc123",
                createdAt: ISO8601DateFormatter().date(from: "2024-01-10T10:15:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2024-02-01T14:45:00Z")!
            ),
            SheetFile(
                id: 6141831453927302,
                name: "Marketing Budget",
                accessLevel: "VIEWER",
                permalink: "https://app.smartsheet.com/b/home?lx=def456",
                createdAt: ISO8601DateFormatter().date(from: "2023-05-12T08:00:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2023-06-15T09:30:00Z")!
            ),
            SheetFile(
                id: 6141831453927303,
                name: "Team Roster",
                accessLevel: "EDITOR",
                permalink: "https://app.smartsheet.com/b/home?lx=ghi789",
                createdAt: ISO8601DateFormatter().date(from: "2024-03-02T12:20:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2024-03-10T13:00:00Z")!
            ),
            SheetFile(
                id: 6141831453927304,
                name: "Sprint Backlog",
                accessLevel: "ADMIN",
                permalink: "https://app.smartsheet.com/b/home?lx=jkl012",
                createdAt: ISO8601DateFormatter().date(from: "2023-11-20T15:10:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2023-12-01T10:45:00Z")!
            ),
            SheetFile(
                id: 6141831453927305,
                name: "Client Contacts",
                accessLevel: "VIEWER",
                permalink: "https://app.smartsheet.com/b/home?lx=mno345",
                createdAt: ISO8601DateFormatter().date(from: "2022-07-18T09:00:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2022-08-22T16:30:00Z")!
            ),
            SheetFile(
                id: 6141831453927306,
                name: "Resource Allocation",
                accessLevel: "EDITOR",
                permalink: "https://app.smartsheet.com/b/home?lx=pqr678",
                createdAt: ISO8601DateFormatter().date(from: "2024-04-01T11:00:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2024-04-05T12:00:00Z")!
            ),
            SheetFile(
                id: 6141831453927307,
                name: "Annual Report",
                accessLevel: "ADMIN",
                permalink: "https://app.smartsheet.com/b/home?lx=stu901",
                createdAt: ISO8601DateFormatter().date(from: "2023-12-31T23:59:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2024-01-01T00:10:00Z")!
            ),
            SheetFile(
                id: 6141831453927308,
                name: "Quarterly Review",
                accessLevel: "EDITOR",
                permalink: "https://app.smartsheet.com/b/home?lx=vwx234",
                createdAt: ISO8601DateFormatter().date(from: "2024-02-15T14:00:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2024-02-16T15:15:00Z")!
            ),
            SheetFile(
                id: 6141831453927309,
                name: "Onboarding Checklist",
                accessLevel: "VIEWER",
                permalink: "https://app.smartsheet.com/b/home?lx=yz567",
                createdAt: ISO8601DateFormatter().date(from: "2023-10-05T08:30:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2023-10-06T09:00:00Z")!
            ),
            SheetFile(
                id: 6141831453927310,
                name: "Event Planning",
                accessLevel: "ADMIN",
                permalink: "https://app.smartsheet.com/b/home?lx=abc890",
                createdAt: ISO8601DateFormatter().date(from: "2022-12-12T10:00:00Z")!,
                modifiedAt: ISO8601DateFormatter().date(from: "2023-01-01T11:00:00Z")!
            )
        ].sorted { $0.name < $1.name }
    }

    var filteredFiles: [SheetFile] {
        if searchText.isEmpty {
            return mockFiles
        }
        return mockFiles.filter { file in
            let lowerSearch = searchText.lowercased()
            return
                file.name.lowercased().contains(lowerSearch) ||
                file.accessLevel.lowercased().contains(lowerSearch) ||
                file.permalink.lowercased().contains(lowerSearch) ||
                String(file.id).contains(lowerSearch) ||
                formattedDate(file.createdAt).lowercased().contains(lowerSearch) ||
                formattedDate(file.modifiedAt).lowercased().contains(lowerSearch)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isPad = geometry.size.width > 600
                Group {
                    if isPad {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(filteredFiles) { file in
                                    makeFileCard(file: file)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(radius: 2))
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    } else {
                        List(filteredFiles) { file in
                            makeFileCard(file: file)
                        }
                    }
                }
                .searchable(text: $searchText)
                .navigationTitle("Select a Sheet")
            }
        }
        .navigationDestination(item: $selectedFile) { _ in
            SpreadsheetViewWrapper()
        }
    }

    private func makeFileCard(file: SheetFile) -> some View {
        Button(action: {
            selectedFile = file
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(file.name)
                    .font(.headline)

                Text("ID: \(String(file.id))")
                    .font(.subheadline)

                Text("Access: \(file.accessLevel)")
                    .font(.subheadline)

                Text("Created: \(formattedDate(file.createdAt))")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Text("Modified: \(formattedDate(file.modifiedAt))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

#Preview {
    SelectFileView()
}
