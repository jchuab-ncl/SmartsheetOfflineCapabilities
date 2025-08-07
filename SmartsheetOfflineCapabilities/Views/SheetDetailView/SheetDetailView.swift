//
//  SheetDetailView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

import SwiftData
import SwiftUI

struct SheetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = SheetDetailViewModel()
    
    private let cachedSheetDTO: CachedSheetDTO    

    var body: some View {        
        ZStack {
            if viewModel.status == .loading {
                ProgressView()
            } else {
                SpreadsheetViewWrapper(sheetContentDTO: viewModel.sheetContentDTO)
            }
        }
        .padding()
        .navigationTitle(cachedSheetDTO.name)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                makeBackButton()
            }
            
            if viewModel.showSaveButton {
                ToolbarItem(placement: .topBarTrailing) {
                    makeSaveButton()
                }
            }
        }
        .onAppear {
            viewModel.loadSheetContent(sheetId: cachedSheetDTO.id)
        }
    }
    
    // MARK: Initializers
    
    /// Initializes the `SheetDetailView` with the provided cached sheet DTO and model context.
    ///
    /// - Parameters:
    ///   - cachedSheetDTO: The cached sheet metadata used to display the sheet name and fetch detailed content.
    init(cachedSheetDTO: CachedSheetDTO) {
        self.cachedSheetDTO = cachedSheetDTO
    }
    
    // MARK: Private methods
    
    private func makeBackButton() -> some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }
    
    private func makeSaveButton() -> some View {
        Button(action: {
            viewModel.saveSheetContent()
        }) {
            HStack {
                Text("Save")
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
