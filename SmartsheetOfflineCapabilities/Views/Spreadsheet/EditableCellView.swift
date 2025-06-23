//
//  EditableCellView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import SwiftUI

struct EditableCellView: View {
    @Binding var text: String

    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .multilineTextAlignment(.center)
            .padding(6)
    }
}
