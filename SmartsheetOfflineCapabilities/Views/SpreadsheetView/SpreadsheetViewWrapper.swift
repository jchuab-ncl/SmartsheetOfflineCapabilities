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
    
    /// Initializes the SpreadsheetViewWrapper with the provided sheet content data.
    /// - Parameter sheetContentDTO: The data transfer object containing the sheet content to display.
    init(sheetContentDTO: SheetContentDTO) {
        self.sheetContentDTO = sheetContentDTO
    }
        
    func makeUIView(context: Context) -> SpreadsheetView {
        let spreadsheetView = SpreadsheetView()
        spreadsheetView.dataSource = context.coordinator
        spreadsheetView.delegate = context.coordinator
        
        // Setup grid size, layout, etc.
        print("Log: SpreadsheetView initialized.")
        
        return spreadsheetView
    }

    func updateUIView(_ uiView: SpreadsheetView, context: Context) {
        // Update logic if needed
        print("Log: updateUIView")
    }

    func makeCoordinator() -> Coordinator {
        print("Log: makeCoordinator")
        
        return Coordinator(sheetContentDTO: self.sheetContentDTO)
    }
}

class Coordinator: NSObject, SpreadsheetViewDelegate {
    private var sheetContentDTO: SheetContentDTO
    private var sheetService: SheetServiceProtocol
    private var textSize: [Int: Int] = [:] //RowId / TextSize
    private var serverInfoFormatParser: ServerInfoFormatParserProtocol
    
    /// Initializes the Coordinator for managing spreadsheet interactions.
    /// - Parameters:
    ///   - sheetContentDTO: The data transfer object containing the sheet content.
    ///   - sheetService: Service protocol for handling sheet updates. Defaults to shared dependency.
    ///   - serverInfoFormatParser: Service protocol for parsing server info formats. Defaults to shared dependency.
    init(
        sheetContentDTO: SheetContentDTO,
        sheetService: SheetServiceProtocol = Dependencies.shared.sheetService,
        serverInfoFormatParser: ServerInfoFormatParserProtocol = Dependencies.shared.serverInfoFormatParserService
    ) {
        self.sheetContentDTO = sheetContentDTO
        self.sheetService = sheetService
        self.serverInfoFormatParser = serverInfoFormatParser
        
        for row in sheetContentDTO.rows {
            for cell in row.cells {
                self.textSize[row.id] = (cell.value?.count ?? 0) > (self.textSize[row.id] ?? 0) ? cell.value?.count ?? 0 : self.textSize[row.id] ?? 0
            }
        }
    }
}

extension Coordinator: CustomEditableCellDelegate {    
    func didChangeText(
        columnType: ColumnType,
        newValue: String,
        oldValue: String,
        selectedContacts: Set<ContactDTO>,
        rowId: Int,
        columnId: Int
    ) {
        /// Saving the changes that the user mades in memory so this could be saved if the user clicks on Save button
        var value = ""
        var selectedContactsArray: [CachedSheetContactUpdatesToPublishDTO] = []
        
        switch columnType {
        case .abstractDateTime, .contactList, .multiContactList, .checkbox, .duration, .predecessor, .textNumber:
            value = newValue
            
            if !selectedContacts.isEmpty {
                selectedContactsArray = selectedContacts.map({
                    .init(
                        sheetId: sheetContentDTO.id,
                        rowId: rowId,
                        columnId: columnId,
                        name: $0.name,
                        email: $0.email
                    ) })
            }
            
        case .date:
            value = newValue.asFormattedDate(inputFormat: "MM/dd/yy", outputFormat: "yyyy-MM-dd")
        case .dateTime:
            value = newValue.asFormattedDate(inputFormat: "MM/dd/yy h:mm a", outputFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
        case .multiPicklist, .picklist:
            value = newValue
        }
        
        //TODO: Update the value and diplayValue fields for the sheetContentDTO.rows.cell filtering by rowId and columnID

        // Update the local DTO so UI reflects changes immediately
        if let rowIndex = sheetContentDTO.rows.firstIndex(where: { $0.id == rowId }) {
            // Find existing cell
            if let cellIndex = sheetContentDTO.rows[rowIndex].cells.firstIndex(where: { $0.columnId == columnId }) {
                sheetContentDTO.rows[rowIndex].cells[cellIndex].value = value
                sheetContentDTO.rows[rowIndex].cells[cellIndex].displayValue = value
            } else {
                // If this cell doesn't exist yet in the row, append it
                let newCell = CellDTO(
                    columnId: columnId,
                    conditionalFormat: nil,
                    value: value,
                    displayValue: value,
                    format: nil
                )
                sheetContentDTO.rows[rowIndex].cells.append(newCell)
            }
        } else {
            // You could log if the row isn't found
            print("⚠️ didChangeText: Row with id \(rowId) not found in sheetContentDTO.")
        }
        
        sheetService.addSheetWithUpdatesToPublishInMemoryRepo(sheet:
                .init(
                    columnType: columnType.rawValue,
                    sheetId: sheetContentDTO.id,
                    name: sheetContentDTO.name,
                    newValue: value,
                    oldValue: oldValue,
                    rowId: rowId,
                    columnId: columnId,
                    contacts: selectedContactsArray
                )
        )
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
        
        let defaultHeight: CGFloat = 80
        
        if self.sheetContentDTO.rows.count > 0 && column > 0 {
            let rowId = self.sheetContentDTO.rows[column - 1].id
            let value = CGFloat((textSize[rowId] ?? 0) / 2)
            return (value > defaultHeight) ? value : defaultHeight
        } else {
            return defaultHeight
        }
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
        var row: RowDTO?
        
        cell.rowNumber = indexPath.row == 0 ? 0 : indexPath.row
        cell.isEditable = true
        if indexPath.row > 0 {
            row = sheetContentDTO.rows[indexPath.row - 1]
            
            if let rowId = row?.id {
                cell.rowId = rowId
            }
            
            cell.rowDiscussions = self.sheetContentDTO.discussionsForRow(row?.id ?? 0)
            cell.allDiscussions = self.sheetContentDTO.discussions
        }
        
        /// Finding the primary column
        let primaryColumn = sheetContentDTO.columns.first(where: {
            guard let primary = $0.primary else {
                return false
            }
            return primary
        })
        
        cell.sheetId = sheetContentDTO.id
        cell.columnPrimaryText = row?.cells.first(where: { $0.columnId == primaryColumn?.id })?.value ?? ""
        cell.isRowNumber = true
        return cell
    }

    private func makeHeaderCell(for indexPath: IndexPath, in spreadsheetView: SpreadsheetView) -> CustomEditableCell {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
        cell.text = sheetContentDTO.columns[indexPath.column - 1].title
        cell.isEditable = false
        cell.isHeader = true
        return cell
    }

    private func makeDataCell(for indexPath: IndexPath, in spreadsheetView: SpreadsheetView) -> CustomEditableCell {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
        cell.delegate = self
        
        let column = sheetContentDTO.columns[indexPath.column - 1]
        let row = sheetContentDTO.rows[indexPath.row - 1]
        let cellData = row.cells.first(where: { $0.columnId == column.id })
        
        print("Log: Conditional Format: ", cellData?.conditionalFormat ?? "empty")
        print("Log: Format: ", cellData?.conditionalFormat ?? "empty")
        print("Log: ========", cellData?.conditionalFormat ?? "empty")
        
        if let format = cellData?.conditionalFormat {
            cell.parsedFormat = serverInfoFormatParser.parse(formatString: format)
        } else if let format = cellData?.format {
            cell.parsedFormat = serverInfoFormatParser.parse(formatString: format)
        }
        
        let value = cellData?.displayValue ?? cellData?.value ?? ""
        self.textSize[row.id] = value.count > (self.textSize[row.id] ?? 0) ? value.count : self.textSize[row.id] ?? 0

        cell.columnType = column.type
        cell.isEditable = column.systemColumnType.isEmpty
        cell.isHeader = false
        cell.contactOptions = column.contactOptions
        cell.pickListValues = []
        cell.rowId = row.id
        cell.columnId = column.id

        switch column.type {
        case .abstractDateTime, .contactList, .multiContactList, .checkbox, .duration, .predecessor, .textNumber:
            
            if column.contactOptions.isEmpty {
                cell.selectedContact = []
            } else {
                cell.pickListValues = column.options
                
                let names: [String] = cellData?.displayValue?.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespaces)
                } ?? []
                
                let contacts: [ContactDTO] = column.contactOptions.filter { names.contains($0.name) }
                
                cell.selectedContact = Set(contacts)
                cell.text = value
            }
            
            cell.text = value
        case .date:
            if let value = cellData?.value {
                cell.text = value.asFormattedDate(inputFormat: "yyyy-MM-dd", outputFormat: "MM/dd/yy")
            }
        case .dateTime:
            if let value = cellData?.value {
                cell.text = value.asFormattedDate(inputFormat: "yyyy-MM-dd'T'HH:mm:ssZ", outputFormat: "MM/dd/yy h:mm a")
            }            
        case .multiPicklist, .picklist:
            cell.pickListValues = column.options
            cell.selectedContact = []
            cell.text = value
        }

        return cell
    }
}
