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
    
    private var sheetContentDTO: SheetContentDTO
    
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
}

class Coordinator: NSObject, SpreadsheetViewDelegate {
    
    private var sheetContentDTO: SheetContentDTO
    private var sheetService: SheetServiceProtocol
    
    init(
        sheetContentDTO: SheetContentDTO,
        sheetService: SheetServiceProtocol = Dependencies.shared.sheetService
    ) {
        self.sheetContentDTO = sheetContentDTO
        self.sheetService = sheetService
    }
}

extension Coordinator: CustomEditableCellDelegate {
    
    func didChangeText(newValue: String, oldValue: String, rowId: Int, columnId: Int) {
        Task {
            do {
                try await sheetService.addSheetHasUpdatesToPublish(
                    sheetId: sheetContentDTO.id,
                    name: sheetContentDTO.name,
                    newValue: newValue,
                    oldValue: oldValue,
                    rowId: rowId,
                    columnId: columnId
                )
            } catch {
                print("❌ Error marking sheet as pending to update. Sheet ID: \(sheetContentDTO.id)")
            }
            print("✅ Text changed: NewValue: \(newValue) OldValue: \(oldValue) RowId: \(rowId) ColumnId: \(columnId)")
        }
    }
}

extension Coordinator: SpreadsheetViewDataSource {
    @objc(spreadsheetView:widthForColumn:)
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        guard column != 0 else {
            return 40
        }

        let width = self.sheetContentDTO.columns[column - 1].width
        
        guard width > 0 else {
            return CGFloat(100)
        }

        return CGFloat(width)
    }
    
    @objc(spreadsheetView:heightForRow:)
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow column: Int) -> CGFloat {
        return 50
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        spreadsheetView.bounces = false
        spreadsheetView.register(CustomEditableCell.self, forCellWithReuseIdentifier: "Cell")

        if indexPath.column == 0 {
            return makeLineNumberCell(for: indexPath, in: spreadsheetView)
        } else if indexPath.row == 0 {
            return makeHeaderCell(for: indexPath, in: spreadsheetView)
        } else {
            return makeDataCell(for: indexPath, in: spreadsheetView)
        }
    }
    
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        let value = self.sheetContentDTO.columns.count(where: { !$0.hidden })
        return value + 1 // Increasing the number of columns to show a column with line numbers
    }

    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        return (self.sheetContentDTO.rows.count) + 1
    }
    
    func frozenRows(in spreadsheetView: SpreadsheetView) -> Int {
        return 1
    }
    
    func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return 1
    }
    
    // MARK: Private methods
    
    private func makeLineNumberCell(for indexPath: IndexPath, in spreadsheetView: SpreadsheetView) -> CustomEditableCell {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
        cell.text = indexPath.row == 0 ? "" : "\(indexPath.row)"
        cell.isEditable = false
        cell.isHeaderOrEnumerated = true
        return cell
    }

    private func makeHeaderCell(for indexPath: IndexPath, in spreadsheetView: SpreadsheetView) -> CustomEditableCell {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
        cell.text = sheetContentDTO.columns[indexPath.column - 1].title
        cell.isEditable = false
        cell.isHeaderOrEnumerated = true
        return cell
    }

    private func makeDataCell(for indexPath: IndexPath, in spreadsheetView: SpreadsheetView) -> CustomEditableCell {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
        cell.delegate = self
        
        let column = sheetContentDTO.columns[indexPath.column - 1]
        let row = sheetContentDTO.rows[indexPath.row - 1]
        let cellData = row.cells.first(where: { $0.columnId == column.id })
        let value = cellData?.displayValue ?? cellData?.value ?? ""

        cell.columnType = column.type
        cell.isEditable = column.systemColumnType.isEmpty
        cell.isHeaderOrEnumerated = false
        cell.contactOptions = column.contactOptions
        cell.pickListValues = []
        cell.rowId = row.id
        cell.columnId = column.id

        switch column.type {
        case .abstractDateTime, .contactList, .multiContactList, .checkbox, .duration, .predecessor, .textNumber:
            cell.text = value
        case .date:
            cell.text = value.asFormattedDate()
        case .dateTime:
            cell.text = value.asFormattedDate(inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ", outputFormat: "MM/dd/yy h:mm a")
        case .multiPicklist, .picklist:
            cell.pickListValues = column.options
            cell.text = value
        }

        return cell
    }
}
