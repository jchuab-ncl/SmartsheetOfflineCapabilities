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
            guard column != 0 else {
                return 40
            }
            
            let width = self.sheetDetailResponse?.columns?[column - 1].width ?? 100
            
            return CGFloat(width)
        }
       
        // Implement required data source & delegate methods here
        func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
            let value = self.sheetDetailResponse?.columns?.count(where: { !($0.hidden ?? false) }) ?? 0
            return value // + 1 Increasing the number of columns to show a column with line numbers
        }
        
        func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
            return (self.sheetDetailResponse?.rows?.count ?? 0) + 1
        }

        func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {            
            spreadsheetView.bounces = false
            
            spreadsheetView.register(CustomEditableCell.self, forCellWithReuseIdentifier: "Cell")
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
            var columnType: ColumnType = .textNumber
            var systemColumnType = ""
            var contactOptions: [Contact] = []
            var text = ""
            
            if indexPath.column == 0 {
                if indexPath.row == 0 {
                    text = ""
                } else {
                    text = "\(indexPath.row)"
                }
                cell.isEditable = false
                cell.isHeaderOrEnumerated = true
            } else if indexPath.row == 0 {
                text = self.sheetDetailResponse?.columns?[indexPath.column - 1].title ?? ""
                cell.isEditable = false
                cell.isHeaderOrEnumerated = true
            } else {
                columnType = self.sheetDetailResponse?.columns?[indexPath.column - 1].type ?? .textNumber
                systemColumnType = self.sheetDetailResponse?.columns?[indexPath.column - 1].systemColumnType ?? ""
                contactOptions = self.sheetDetailResponse?.columns?[indexPath.column - 1].contactOptions ?? []
                
                let value = self.sheetDetailResponse?.rows?[indexPath.row - 1].cells?[indexPath.column - 1].displayValue ?? self.sheetDetailResponse?.rows?[indexPath.row - 1].cells?[indexPath.column - 1].value ?? ""
                
                switch columnType {
                case .abstractDateTime, .contactList, .multiContactList, .checkbox, .duration, .predecessor, .textNumber:
                    cell.pickListValues = []
                    cell.contactOptions = contactOptions
                    text = value
                    break

                case .date:
                    cell.pickListValues = []
                    text = value.asFormattedDate()
                    break
                    
                case .dateTime:
                    text = value.asFormattedDate(
                        inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ",
                        outputFormat: "MM/dd/yy h:mm a"
                    )
                    break

                case .multiPicklist, .picklist:
                    text = value
                    cell.pickListValues = self.sheetDetailResponse?.columns?[indexPath.column - 1].options ?? []
                    break
                }
            }
            
            if systemColumnType.isNotEmpty {
                cell.isEditable = false
            }
            cell.columnType = columnType
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
