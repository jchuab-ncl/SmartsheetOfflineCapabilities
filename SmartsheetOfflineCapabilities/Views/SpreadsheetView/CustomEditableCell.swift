//
//  CustomEditableCell.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import UIKit
import SpreadsheetView
import SwiftUI

class CustomEditableCell: Cell {
    private var hostingController: UIHostingController<EditableCellView>?
    var text: String = "" {
        didSet {
            updateContent()
        }
    }

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
    }

    private func updateContent() {
        let view = EditableCellView(text: Binding(get: {
            self.text
        }, set: { newText in
            self.text = newText
            print("LOG:", newText)
            // Optional: notify model or delegate
        }))

        hostingController = UIHostingController(rootView: view)
        if let hostingView = hostingController?.view {
            hostingView.backgroundColor = .clear
            hostingView.frame = contentView.bounds
            hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(hostingView)
        }
    }
}
