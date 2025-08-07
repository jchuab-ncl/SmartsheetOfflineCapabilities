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

    // State for contact selection
    @State private var selectedNames: Set<String> = []
    
    // MARK: Private properties
    
    var isEditable: Bool = false
    var pickListValues: [String] = []
    var columnType: ColumnType = .textNumber
    var isHeaderOrEnumerated: Bool = false
    var contactOptions: [ContactDTO] = []
    
    // MARK: View body

    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, minHeight: 44)
            .bold(isHeaderOrEnumerated)
            .multilineTextAlignment(.center)
            .padding(6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .onTapGesture {
                isEditing = true
            }
            .sheet(isPresented: Binding(
                get: {
                    isEditing && isEditable
                },
                set: { newValue in
                    isEditing = newValue
                }
            )) {
                makeSheet()
            }
            .onAppear {
                if !contactOptions.isEmpty {
                    selectedNames = Set(
                        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    )
                }
            }
    }
    
    private func makeSheet() -> some View {
        VStack {
            Text("Edit Content")
                .font(.headline)
                .padding()

            if columnType == .date {
                buildDateSheet()
            } else if !pickListValues.isEmpty {
                buildPickerSheet()
            } else if !contactOptions.isEmpty {
                buildContactSheet()
            } else {
                TextEditor(text: $text)
                    .padding()
            }

            HStack(spacing: 40) {
                if columnType == .date {
                    Button("Clear date") {
                        text = ""
                    }
                    .foregroundColor(.red)
                }
                
                Button("Close") {
                    isEditing = false
                }
            }
            .padding(.bottom, 16)
        }
        .presentationDetents([.medium, .large])
    }
    
    private func buildDateSheet() -> some View {
        let bindingDate = Binding<Date>(
            get: {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy"
                return formatter.date(from: text) ?? Date()
            },
            set: { newDate in
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy"
                text = formatter.string(from: newDate)
            }
        )

        return DatePicker("", selection: bindingDate, displayedComponents: .date)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
    }
    
    private func buildPickerSheet() -> some View {
        Picker("Select Value", selection: $text) {
            ForEach([""] + pickListValues.sorted(by: { $0 < $1 }), id: \.self) { value in
                Text(value).tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .padding()
    }

    private func buildContactSheet() -> some View {
        // Multi-select list of contacts with checkmarks
        List {
            ForEach(contactOptions.sorted(by: { $0.name < $1.name }).map({ $0.name }), id: \.self) { value in
                let isSelected = selectedNames.contains(value)
                HStack {
                    Text(value)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelected {
                        selectedNames.remove(value)
                    } else {
                        selectedNames.insert(value)
                    }
                    text = selectedNames.sorted().joined(separator: ", ")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
