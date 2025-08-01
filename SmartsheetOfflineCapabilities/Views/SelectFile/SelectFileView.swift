//
//  SelectFileView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 11/06/25.
//

import SwiftData
import SwiftUI

struct SelectFileView: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    @StateObject private var viewModel: SelectFileViewModel
    
    @State private var selectedFile: CachedSheetDTO?
    @State private var searchText = ""
    
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
                let isPad = geometry.size.width > 600
                Group {
                    if viewModel.status == .loading {
                        ProgressView()
                            .frame(width: geometry.size.width)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    } else if viewModel.status == .error {
                        makeErrorView()
                    } else if filteredFiles.isEmpty {
                        makeEmptyView()
                    } else if isPad {
                        makeiPadView()
                    } else {
                        List(filteredFiles) { file in
                            makeFileCard(file: file)
                        }
                    }
                }
                .refreshable {
                    viewModel.loadSheets()
                }
                .searchable(text: $searchText)
                .navigationTitle("Select a Sheet")
            }
            .onAppear {
                viewModel.loadSheets()
            }
        }
        .navigationDestination(item: $selectedFile) { file in
            SheetDetailView(cachedSheetDTO: file, modelContext: modelContext)
        }
    }
    
    // MARK: Initializers
    
    init(modelContext: ModelContext) {
        self._viewModel = .init(wrappedValue: SelectFileViewModel(modelContext: modelContext))
    }
    
    // MARK: Private methods
    
    private func makeiPadView() -> some View {
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
    }
        
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

    private func makeFileCard(file: CachedSheetDTO) -> some View {
        Button(action: {
            selectedFile = file
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(file.name)
                    .font(.headline)

                Text("Modified: \(file.modifiedAt)")
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

//#Preview {
//    SelectFileView()
//}
