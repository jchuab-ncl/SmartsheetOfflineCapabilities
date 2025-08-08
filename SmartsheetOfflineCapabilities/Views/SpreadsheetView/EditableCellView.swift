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

    // Stage edits here; commit to `text` on Done
    @State private var draftText: String = ""

    // State for contact selection
    @State private var selectedNames: Set<String> = []

    // MARK: Private properties
    var isEditable: Bool = false
    var pickListValues: [String] = []
    var columnType: ColumnType = .textNumber
    var isHeaderOrEnumerated: Bool = false
    var contactOptions: [ContactDTO] = []

    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, minHeight: 44)
            .bold(isHeaderOrEnumerated)
            .multilineTextAlignment(.center)
            .padding(6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .onTapGesture {
                // Initialize the draft from current bound value
                draftText = text
                isEditing = true
            }
            .sheet(isPresented: Binding(
                get: { isEditing && isEditable },
                set: { newValue in isEditing = newValue }
            )) {
                makeSheet()
            }
            .onAppear {
                // Keep existing contact preselect when rendering cells (non-blocking)
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
                // Bind editor to the draft
                TextEditor(text: $draftText)
                    .padding()
            }

            HStack(spacing: 40) {
                if columnType == .date {
                    Button("Clear date") {
                        draftText = ""
                    }
                    .foregroundColor(.red)
                }

                Button("Done") {
                    // Commit the staged value and close
                    text = draftText
                    isEditing = false
                }
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            // Re-seed draft (and contact selection) each time the sheet shows
            draftText = text
            if !contactOptions.isEmpty {
                selectedNames = Set(
                    draftText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                )
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func buildDateSheet() -> some View {
        let bindingDate = Binding<Date>(
            get: {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy"
                return formatter.date(from: draftText) ?? Date()
            },
            set: { newDate in
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy"
                draftText = formatter.string(from: newDate)
            }
        )

        return DatePicker("", selection: bindingDate, displayedComponents: .date)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
    }

    private func buildPickerSheet() -> some View {
        Picker("Select Value", selection: $draftText) {
            ForEach([""] + pickListValues.sorted(), id: \.self) { value in
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
                    // Stage the concatenated selection
                    draftText = selectedNames.sorted().joined(separator: ", ")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
