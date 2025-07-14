//
//  EditableCellView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import SwiftUI

struct EditableCellView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var isEditing: Bool = false

    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, minHeight: 44)
            .multilineTextAlignment(.center)
            .padding(6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .onTapGesture {
                isEditing = true
            }
            .sheet(isPresented: $isEditing) {
                VStack {
                    Text("Edit Content")
                        .font(.headline)
                        .padding()
                    TextEditor(text: $text)
                        .padding()
                    Button("Done") {
                        isEditing = false
                    }
                    .padding()
                }
                .presentationDetents([.medium, .large])
            }
    }
}
