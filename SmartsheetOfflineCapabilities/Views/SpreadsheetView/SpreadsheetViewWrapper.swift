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
    
    private var sheetContentDTO: SheetContentDTO?
    
    // MARK: Initializers
    
    init(sheetContentDTO: SheetContentDTO) {
        self.sheetContentDTO = sheetContentDTO
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
        Coordinator(sheetContentDTO: self.sheetContentDTO)
    }

    class Coordinator: NSObject, SpreadsheetViewDataSource, SpreadsheetViewDelegate {
        
        private var sheetContentDTO: SheetContentDTO?
        
        init(sheetContentDTO: SheetContentDTO? = nil) {
            self.sheetContentDTO = sheetContentDTO
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
            
            guard let width = self.sheetContentDTO?.columns[column - 1].width else {
                return CGFloat(100)
            }
            
            return CGFloat(width)
        }
       
        // Implement required data source & delegate methods here
        func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
            let value = self.sheetContentDTO?.columns.count(where: { !$0.hidden }) ?? 0
            return value + 1 // Increasing the number of columns to show a column with line numbers
        }
        
        func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
            return (self.sheetContentDTO?.rows.count ?? 0) + 1
        }

        func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {            
            spreadsheetView.bounces = false
            
            spreadsheetView.register(CustomEditableCell.self, forCellWithReuseIdentifier: "Cell")
            let customEditableCell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
            var columnType: ColumnType = .textNumber
            var systemColumnType = ""
            var contactOptions: [ContactDTO] = []
            var options: [String] = []
            var text = ""
            
            if indexPath.column == 0 {
                if indexPath.row == 0 {
                    text = ""
                } else {
                    text = "\(indexPath.row)"
                }
                customEditableCell.isEditable = false
                customEditableCell.isHeaderOrEnumerated = true
            } else if indexPath.row == 0 {
                text = self.sheetContentDTO?.columns[indexPath.column - 1].title ?? ""
                customEditableCell.isEditable = false
                customEditableCell.isHeaderOrEnumerated = true
            } else {
                let columnId = self.sheetContentDTO?.columns[indexPath.column - 1].id
                columnType = self.sheetContentDTO?.columns[indexPath.column - 1].type ?? .textNumber
                systemColumnType = self.sheetContentDTO?.columns[indexPath.column - 1].systemColumnType ?? ""
                contactOptions = self.sheetContentDTO?.columns[indexPath.column - 1].contactOptions ?? []
                options = self.sheetContentDTO?.columns[indexPath.column - 1].options ?? []
                
                let cell = self.sheetContentDTO?.rows[indexPath.row - 1].cells.first(where: { $0.columnId == columnId })
                let value = cell?.displayValue ?? cell?.value ?? ""
                
                switch columnType {
                case .abstractDateTime, .contactList, .multiContactList, .checkbox, .duration, .predecessor, .textNumber:
                    customEditableCell.pickListValues = []
                    customEditableCell.contactOptions = contactOptions
                    text = value
                    break

                case .date:
                    customEditableCell.pickListValues = []
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
                    customEditableCell.pickListValues = options
                    break
                }
            }
            
            if systemColumnType.isNotEmpty {
                customEditableCell.isEditable = false
            }
            customEditableCell.columnType = columnType
            customEditableCell.text = text
            return customEditableCell
        }
        
        func frozenRows(in spreadsheetView: SpreadsheetView) -> Int {
            return 1
        }
        
        func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int {
            return 1
        }
    }
}
