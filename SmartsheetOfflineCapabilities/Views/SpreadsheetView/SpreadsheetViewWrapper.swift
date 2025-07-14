//
//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import SwiftUI
import SpreadsheetView

struct SpreadsheetViewWrapper: UIViewRepresentable {
    
    // MARK: Private properties
    
//    @StateObject private var viewModel = SpreadsheetViewWrapperViewModel()
    
//    private var sheetId: Int64
    private var sheetDetailResponse: SheetDetailResponse?
    
    // MARK: Initializers
    
    init(sheetDetailResponse: SheetDetailResponse) {
        self.sheetDetailResponse = sheetDetailResponse
    }
        
    func makeUIView(context: Context) -> SpreadsheetView {
        let spreadsheetView = SpreadsheetView()
        spreadsheetView.dataSource = context.coordinator
        spreadsheetView.delegate = context.coordinator
        
        // Setup grid size, layout, etc.
        return spreadsheetView
    }

    func updateUIView(_ uiView: SpreadsheetView, context: Context) {
        // Update logic if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(sheetDetailResponse: self.sheetDetailResponse)
    }

    class Coordinator: NSObject, SpreadsheetViewDataSource, SpreadsheetViewDelegate {
        
        private var sheetDetailResponse: SheetDetailResponse?
        
        init(sheetDetailResponse: SheetDetailResponse? = nil) {
            self.sheetDetailResponse = sheetDetailResponse
        }
        
        @objc(spreadsheetView:heightForRow:)
        func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow column: Int) -> CGFloat {
            return 50
        }
        
        @objc(spreadsheetView:widthForColumn:)
        func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
            return column == 0 ? 40 : 100                
        }
       
        // Implement required data source & delegate methods here
        func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
            let value = self.sheetDetailResponse?.columns?.count(where: { !($0.hidden ?? false) }) ?? 0
            return value // + 1 // Increasing the number of columns to show a column with line numbers
        }
        
        func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
            return (self.sheetDetailResponse?.rows?.count ?? 0) + 1
        }

        func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {            
            spreadsheetView.bounces = false
            
            spreadsheetView.register(CustomEditableCell.self, forCellWithReuseIdentifier: "Cell")
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
            
            var text = ""
            
            if indexPath.column == 0 {
                if indexPath.row == 0 {
                    text = ""
                } else {
                    text = "\(indexPath.row)"
                }
            } else if indexPath.row == 0 {
                text = self.sheetDetailResponse?.columns?[indexPath.column].title ?? ""
            } else {
                text = self.sheetDetailResponse?.rows?[indexPath.row - 1].cells?[indexPath.column].displayValue ?? self.sheetDetailResponse?.rows?[indexPath.row - 1].cells?[indexPath.column].value ?? ""
            }
            
            cell.text = text
            return cell
        }
        
        func frozenRows(in spreadsheetView: SpreadsheetView) -> Int {
            return 1
        }
        
        func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int {
            return 1
        }
    }
}
