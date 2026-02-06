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
                            Text(type.rawValue.capitalized).tag(type)
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
                    
                    Text("Total logs: \(viewModel.filteredLogs.count)")
                        .font(.footnote)
                        .padding()
                }
                .navigationTitle("Logs")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Clear all logs") {
                                viewModel.clearAllLogs()
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
    }
}
