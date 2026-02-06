//
//  EditableCellView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab Rosa Costa on 06/06/25.
//

import SwiftUI

struct EditableCellView: View {
    @Binding var text: String
    @State var selectedContact: Set<ContactDTO> = []
    
    @StateObject private var viewModel = EditableCellViewModel()
    
    @State private var isEditing: Bool = false

    // Stage edits here; commit to `text` on Done
    @State private var draftText: String = ""
    
    @State private var showConflictResolutionSheet: Bool = false
    
    @Binding var conflict: Conflict?
    
    var isEditable: Bool = false
    var isClickable: Bool = false
    var pickListValues: [String] = []
    var columnType: ColumnType = .textNumber
    var columnPrimaryText: String = ""
    var isHeader: Bool = false /// Represents the header, with columns titles
    var isRowNumber: Bool = false /// Represents the first column, showing line/row numbers
    var rowId: Int = 0
    var sheetId: Int
    var rowNumber: Int = 0
    var contactOptions: [ContactDTO] = []
    var rowDiscussions: [DiscussionDTO] = []
    var allDiscussions: [DiscussionDTO] = []
    var parsedFormat: ParsedFormat = .empty
    
    var displayText: String {
        if isRowNumber {
            if rowNumber == 0 {
                return ""
            } else if rowNumber > 0 {
                return "\(rowNumber)"
            } else {
                return ""
            }
        } else {
            return text
        }
    }

    var body: some View {
        if conflict != nil {
            makeConflictedCellView()
        } else {
            makeCellView()
        }
    }
    
    private func makeCellView() -> some View {
        VStack {
            Text(displayText)
                .foregroundStyle(parsedFormat.textColor)
                .frame(maxWidth: .infinity, minHeight: 44)
                .bold(isHeader || isRowNumber || parsedFormat.bold)
                .italic(parsedFormat.italic)
                .multilineTextAlignment(parsedFormat.horizontalAlign)
                .padding(6)
                .cornerRadius(6)
                .sheet(isPresented: Binding(
                    get: {
                        isEditing && isEditable
                    },
                    set: { newValue in isEditing = newValue }
                )) {
                    makeSheet()
                }
                .onAppear {
                    guard !contactOptions.isEmpty else { return }
                    selectedContact = mapDraftTextToSelectedContacts(text)
                }
            
            if isRowNumber && rowNumber > 0 {
                if rowDiscussions.isEmpty {
                    Image(systemName: "bubble")
                        .padding(.bottom, 12)
                } else {
                    Image(systemName: "bubble.fill")
                        .foregroundStyle(Colors.blueNCL)
                        .padding(.bottom, 12)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Initialize the draft from current bound value
            draftText = text
            
            /// Comments are not available for rows that weren't send to the server yet.
            if rowId <= 0 && isRowNumber {
                isEditing = false
            } else {
                isEditing = true
            }
        }
        .background(parsedFormat.backgroundColor)
    }
    
    private func makeConflictedCellView() -> some View {
        VStack {
            Image(systemName: "doc.on.doc")
                .foregroundStyle(.red)
        }
        .onTapGesture {
            showConflictResolutionSheet = true
        }
        .sheet(isPresented: $showConflictResolutionSheet) {
            makeConflictResolutionSheet()
        }
    }
    
    private func makeConflictResolutionSheet() -> some View {
        ScrollView {
            VStack {
                Text("Conflict Resolution")
                    .font(.headline)
                    .padding()
                
                Text("Someone else updated at the same time as you. Choose how you want to resolve this conflict.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding()
                
                if let conflict = self.conflict {
                    makeSomeoneElseView(conflict: conflict)
                    
                    Divider()
                        .padding(.vertical)
                    
                    makeMyChangeView(conflict: conflict)
                }
                
//                Spacer()
            }
        }
        .padding()
    }
    
    private func makeSomeoneElseView(conflict: Conflict) -> some View {
        VStack(alignment: .center) {
            Text("Someone else change:")
                .font(.subheadline)
                .bold()
            
            Text(viewModel.formatData(value: conflict.serverValue, columnType: conflict.columnType))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            Button(action: {
                viewModel.discardLocalChanges(conflict: conflict)
                draftText = viewModel.formatData(value: conflict.serverValue, columnType: conflict.columnType)
                text = draftText
                self.conflict?.isResolved = true
                showConflictResolutionSheet = false
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Colors.blueNCL)
                        .frame(height: 40)
                    HStack {
                        if viewModel.status == .initial {
                            Text("Keep someone else's change")
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding()
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                                .font(.callout)
                        } else if viewModel.status == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                }
            })
            .frame(height: 40)
            .frame(maxWidth: 300)
            .buttonStyle(.plain)
            .padding(.top)
        }
    }
    
    private func makeMyChangeView(conflict: Conflict) -> some View {
        VStack(alignment: .center)  {
            Text("My change:")
                .font(.subheadline)
                .bold()
            
            Text(viewModel.formatData(value: conflict.localValue, columnType: conflict.columnType))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
                .background(Color.gray.opacity(0.2))
                .fixedSize(horizontal: false, vertical: true)
                .cornerRadius(8)
            
            Button(action: {
                draftText = viewModel.formatData(value: conflict.localValue, columnType: conflict.columnType)
                text = draftText
                self.conflict?.isResolved = true
                showConflictResolutionSheet = false
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Colors.blueNCL)
                        .frame(height: 44)
                    HStack {
                        Text("Keep my change")
                            .padding()
                            .foregroundStyle(.white)
                            .fontWeight(.medium)
                    }
                }
            })
//            .frame(height: 40)
            .frame(maxWidth: 300)
            .buttonStyle(.plain)
            .padding(.top)
        }
    }

    private func makeSheet() -> some View {
        VStack {
            if columnType == .date {
                Text("Edit Content")
                    .font(.headline)
                    .padding()
                buildDateSheet()
            } else if isRowNumber {
                Text("Conversations")
                    .font(.headline)
                    .padding()
                buildDiscussionSheet()
            } else if !pickListValues.isEmpty {
                Text("Edit Content")
                    .font(.headline)
                    .padding()
                buildPickerSheet()
            } else if !contactOptions.isEmpty {
                Text("Edit Content")
                    .font(.headline)
                    .padding()
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
                selectedContact = mapDraftTextToSelectedContacts(draftText)
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
            ForEach(contactOptions.sorted(by: { $0.name < $1.name }), id: \.self) { contact in
                
                HStack {
                    Text(contact.name)
                    Spacer()
                    let isSelected = selectedContact.contains(contact)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    tapGestureAction(contact: contact)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func buildDiscussionSheet() -> some View {
        DiscussionView(
            allDiscussions: allDiscussions,
            sheetId: sheetId,
            rowDiscussions: rowDiscussions,
            rowNumber: rowNumber,
            rowId: rowId,
            columnPrimaryText: columnPrimaryText
        )
    }
    
    private func tapGestureAction(contact: ContactDTO) {
        let isSelected = selectedContact.contains(contact)
        if isSelected {
            selectedContact.remove(contact)
        } else {
            selectedContact.insert(contact)
        }
        
        // Stage the concatenated selection
        draftText = selectedContact.sorted(by: { $0.name < $1.name }).map { $0.name }.joined(separator: ", ")
    }
    
    private func mapDraftTextToSelectedContacts(_ text: String) -> Set<ContactDTO> {
        return Set(
            text.split(separator: ",").map { substring in
                let name = substring.trimmingCharacters(in: .whitespaces)
                let contact = contactOptions.first { $0.name == name }
                return contact ?? .init(email: "", name: "")
            }
        )
    }
}
