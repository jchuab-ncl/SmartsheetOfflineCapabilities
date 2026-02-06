//
//  LogListView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 05/02/26.
//

import SwiftUI

struct LogListView: View {
    
    /// A flag Indicating if the share view must be presented or not.
    @State private var isShareViewPresented = false
    @State private var showClearLogsConfirmation = false
    
    @StateObject private var viewModel = LogListViewModel()
    
    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView()
                    .navigationTitle("Logs")
            } else {
                VStack {
                    Picker("Filter", selection: $viewModel.selectedType) {
                        ForEach(LogEntryType.allCases, id: \.self) { type in
                            Text(type == .all ? "All" : type.rawValue.capitalized)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    List(viewModel.filteredLogs) { log in
                        VStack(alignment: .leading) {
                            
                            Text("[\(log.context)] \(log.message)")
                                .font(.body)
                            //TODO: Update to show the
                            Text(log.dateTime.asFormattedString())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("Total logs: \(viewModel.filteredLogs.count)")
                            .font(.footnote)
                            .padding()
                        
                        Spacer()
                        
                        Text(AppInfo.versionBuildFormatted)
                            .font(.footnote)
                            .padding()
                    }                    
                }
                .navigationTitle("Logs")
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search logs"
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Clear all logs", role: .destructive) {
                                showClearLogsConfirmation = true
                            }
                            Button("Share logs") {
                                isShareViewPresented = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadLogs()
        }
        .sheet(isPresented: $isShareViewPresented) {
            ShareSheetComponent(items: [viewModel.shareText()])
        }
        .confirmationDialog(
            "Clear all logs?",
            isPresented: $showClearLogsConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear all logs", role: .destructive) {
                viewModel.clearAllLogs()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action will permanently remove all logs and cannot be undone.")
        }
    }
}
