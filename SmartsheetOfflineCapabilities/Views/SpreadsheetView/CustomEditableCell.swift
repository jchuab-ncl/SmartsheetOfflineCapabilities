//
//  CustomEditableCell.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import UIKit
import SpreadsheetView
import SwiftUI

protocol CustomEditableCellDelegate: AnyObject {
    func didChangeText(
        columnType: ColumnType,
        newValue: String,
        oldValue: String,
        selectedContacts: Set<ContactDTO>,
        rowId: Int,
        columnId: Int
    )
}

class CustomEditableCell: Cell {
    private var hostingController: UIHostingController<EditableCellView>?
    
    var text: String = "" {
        didSet {
            updateContent()
        }
    }
    
    /// The row number showing to the user, starts at 1
    var rowNumber: Int = 0 {
        didSet {
            updateContent()
        }
    }
    
    var selectedContact: Set<ContactDTO> = [] {
        didSet {
            updateContent()
        }
    }
    
    var isRowNumber: Bool = false {
        didSet {
            updateContent()
        }
    }
    
    var isHeader: Bool = false {
        didSet {
            updateContent()
        }
    }
    
    var delegate: CustomEditableCellDelegate?
    var isEditable: Bool = true
    var pickListValues: [String] = []
    var columnType: ColumnType = .textNumber
    var columnPrimaryText: String = ""
    var rowId: Int = 0
    var columnId: Int = 0
    var contactOptions: [ContactDTO] = []
    var sheetId: Int = 0
    var rowDiscussions: [DiscussionDTO] = []
    var allDiscussions: [DiscussionDTO] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 0.5
        updateContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateContent()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostingController?.view.removeFromSuperview()
        hostingController = nil
        isHeader = false
        isRowNumber = false
    }

    private func updateContent() {
        // Remove the old hosting view if it exists
        hostingController?.view.removeFromSuperview()
        
        // Create the SwiftUI view
        let view = EditableCellView(
            text: Binding(
                get: {
                    self.text
                },
                set: { newValue in
                    let newContact = self.contactOptions.filter({ newValue.contains($0.name) })
                    let oldValue = self.text
                    self.text = newValue
                    self.delegate?.didChangeText(
                        columnType: self.columnType,
                        newValue: newValue,
                        oldValue: oldValue,
                        selectedContacts: Set(newContact),
                        rowId: self.rowId,
                        columnId: self.columnId
                    )
                }
            ),
            isEditable: isEditable,
            pickListValues: pickListValues,
            columnType: columnType,
            columnPrimaryText: columnPrimaryText,
            isHeader: isHeader,
            isRowNumber: isRowNumber,
            rowId: rowId,
            sheetId: sheetId,
            rowNumber: rowNumber,
            contactOptions: contactOptions,
            rowDiscussions: rowDiscussions,
            allDiscussions: allDiscussions
        )
        
        // Create and assign new hosting controller
        hostingController = UIHostingController(rootView: view)
        
        if let hostingView = hostingController?.view {
            hostingView.backgroundColor = .clear
            hostingView.frame = contentView.bounds
            hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(hostingView)
        }
    }
}
