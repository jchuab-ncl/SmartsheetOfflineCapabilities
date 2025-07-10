//
//  Untitled.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import SwiftUI
import SpreadsheetView

struct SpreadsheetViewWrapper: UIViewRepresentable {
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
        Coordinator()
    }

    class Coordinator: NSObject, SpreadsheetViewDataSource, SpreadsheetViewDelegate {
        @objc(spreadsheetView:heightForRow:)
        func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow column: Int) -> CGFloat {
            return 50
        }
        
        @objc(spreadsheetView:widthForColumn:)
        func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
            return 100
        }
       
        // Implement required data source & delegate methods here
        func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int { return 15 }
        func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int { return 30 }

        func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {            
            spreadsheetView.bounces = false
            
            spreadsheetView.register(CustomEditableCell.self, forCellWithReuseIdentifier: "Cell")
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomEditableCell ?? CustomEditableCell()
            let text = "R\(indexPath.row), C\(indexPath.column)"
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
