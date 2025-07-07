//
//  SheetServiceMessage.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 01/07/25.
//

enum SheetServiceMessage: String, Error {
    
    case empty = ""
    
    var description: String {
        self.rawValue
    }    
}
