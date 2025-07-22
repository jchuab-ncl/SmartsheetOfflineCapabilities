//
//  SheetDetailView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 08/07/25.
//

import SwiftUI

struct SheetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = SheetDetailViewModel()
    
    let sheetFile: CachedSheet

    var body: some View {        
        ZStack {
            if viewModel.status == .loading {
                ProgressView()
            } else {
                if let sheetDetailResponse = viewModel.sheetDetailResponse {
                    SpreadsheetViewWrapper(sheetDetailResponse: sheetDetailResponse)
                }
            }
        }
        .padding()
        .navigationTitle(sheetFile.name)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                makeBackButton()
            }
        }
        .onAppear {
            viewModel.loadSheetContent(sheetId: sheetFile.id)
        }
    }
    
    private func makeBackButton() -> some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back") // Custom back button label
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
