//
//  SheetListView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 11/06/25.
//

import SwiftData
import SwiftUI

struct SheetListView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = SheetListViewModel()
    
    @State private var selectedFile: CachedSheetDTO?
    @State private var searchText = ""
    @State private var showDiscardAlert = false
    
    @State private var selectedSheet: CachedSheetDTO?
    
    var filteredFiles: [CachedSheetDTO] {
        if searchText.isEmpty {
            return viewModel.sheetsList
        }
        return viewModel.sheetsList.filter { file in
            let lowerSearch = searchText.lowercased()
            return
                file.name.lowercased().contains(lowerSearch)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    if viewModel.status == .loading {
                        ProgressView()
                            .frame(width: geometry.size.width)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    } else if viewModel.status == .error {
                        makeErrorView()
                    } else if filteredFiles.isEmpty {
                        makeEmptyView()
                    } else {
                        List(filteredFiles) { file in
                            makeCard(sheet: file)
                        }
                        .refreshable {
                            viewModel.loadSheets()
                        }
                        .navigationTitle("Select a Sheet")
                    }
                    
                    Spacer()
                    
                    if !viewModel.isInternetAvailable {
                        Text("Offline mode. No connection available at the moment.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 12) // small padding from bottom
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .alert("Discard all changes?", isPresented: $showDiscardAlert) {
                Button("Yes", role: .destructive) {
                    viewModel.discardLocalChanges(sheetId: selectedSheet?.id ?? 0)                    
                }
                Button("No", role: .cancel) {
                   showDiscardAlert = false
                }
            } message: {
                Text("Are you sure you want to discard your changes? This action cannot be undone.")
            }
            .onAppear {
                viewModel.loadSheets()
            }
        }
        .navigationDestination(item: $selectedFile) { file in
            SheetContentView(cachedSheetDTO: file, conflictResult: viewModel.conflicts)
        }
    }
    
    // MARK: Private methods
        
    private func makeErrorView() -> some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 12) {
                    Spacer()
                    
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.orange)
                    Text("Something went wrong.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("Please try again.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
    
    private func makeEmptyView() -> some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 12) {
                    Spacer()
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No files to display")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
    
    private func makeCard(sheet: CachedSheetDTO) -> some View {
        // Card container is now a plain view with onTapGesture,
        // so the inner button can receive taps normally.
        VStack(alignment: .leading, spacing: 6) {
            Text(sheet.name)
                .font(.headline)

            Text("Modified: \(sheet.modifiedAt.asFormattedDate(inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ", outputFormat: "MM/dd/yy h:mm a"))")
                .font(.footnote)
                .foregroundColor(.secondary)

            if viewModel.sheetsContentList.first(where: { $0.id == sheet.id }) != nil {
                Text("Available offline  ✅")
                    .foregroundStyle(.green)
                    .font(.footnote)
            }
                                    
            if viewModel.shouldShowResolveConflictsButton(sheetId: sheet.id) {
                makeCardConflictsView(sheet: sheet)
                makeCardDiscardChangesView(sheet: sheet)
            } else if viewModel.shouldShowSyncButton(sheetId: sheet.id) {
                makeCardSyncView(sheet: sheet)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .contentShape(Rectangle()) // full-card tap target
        .onTapGesture {
            selectedFile = sheet
        }
        .accessibilityAddTraits(.isButton)
    }
    
    private func makeCardSyncView(sheet: CachedSheetDTO) -> some View {
        VStack(alignment: .leading) {
            Text("Sheet has content to be sent to server.")
                .foregroundStyle(.red)
                .font(.footnote)
            
            Divider()
                .padding(.vertical)

            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    print(">>> Sync now button tapped for sheet: \(sheet.id)")
                    viewModel.syncData(sheetId: sheet.id)
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Colors.blueNCL)
                            .frame(height: 44)
                        HStack {
                            if viewModel.statusSync[sheet.id] == nil || viewModel.statusSync[sheet.id] == .success {
                                Text("Sync now")
                                    .foregroundStyle(.white)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(.white)
                            } else if viewModel.statusSync[sheet.id] == .loading {
                                Text("Sync in progress")
                                    .foregroundStyle(.white)
                                    .fontWeight(.medium)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else if viewModel.statusSync[sheet.id] == .error {
                                Text("An error has occurred. Try again later.")
                                    .foregroundStyle(.white)
                                    .fontWeight(.medium)
                                Image(systemName: "exclamationmark.icloud")
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                })
                .frame(maxWidth: 300)
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    private func makeCardConflictsView(sheet: CachedSheetDTO) -> some View {
        VStack(alignment: .leading) {
            Text("Sheet has content conflicts to be solved.")
                .foregroundStyle(.red)
                .font(.footnote)
            
            Divider()
                .padding(.vertical)

            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    selectedFile = sheet
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Colors.blueNCL)
                            .frame(height: 44)
                        HStack {
                            Text("Resolve conflicts")
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                            
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.white)
                        }
                    }
                })
                .frame(maxWidth: 300)
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    private func makeCardDiscardChangesView(sheet: CachedSheetDTO) -> some View {
        HStack {
            Spacer()
            
            Button(action: {
                self.selectedSheet = sheet
                showDiscardAlert = true
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blueNCL)
                        .frame(height: 44)
                    HStack {
                        if viewModel.statusDiscard[sheet.id] == nil || viewModel.statusDiscard[sheet.id] == .success {
                            Text("Discard all local changes")
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                            
                            Image(systemName: "trash")
                                .foregroundStyle(.white)
                        } else if viewModel.statusDiscard[sheet.id] == .loading {
                            Text("Discarding...")
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else if viewModel.statusDiscard[sheet.id] == .error {
                            Text("An error has occurred. Try again later.")
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                            Image(systemName: "exclamationmark.icloud")
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            .frame(maxWidth: 300)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.top, 8)
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
    SheetListView()
}
