//
//  ProgressStatus.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 25/06/25.
//

enum ProgressStatus: String {
    case initial
    case loading
    case success
    case error

    var icon: String {
        switch self {
        case .initial:
            return "💡"
        case .loading:
            return "⏳"
        case .success:
            return "✅"
        case .error:
            return "❌"
        }
    }
}
