//
//  LogListViewModel.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 05/02/26.
//

import Foundation
import SwiftUI

@MainActor
final class LogListViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All logs loaded from persistence.
    @Published private(set) var logs: [LogEntry] = []

    /// Logs filtered by the selected type.
    @Published private(set) var filteredLogs: [LogEntry] = []

    /// Indicates whether logs are being loaded.
    @Published var isLoading: Bool = false

    /// Currently selected log type filter.
    /// Defaults to `.error`.
    @Published var selectedType: LogEntryType = .error {
        didSet {
            applyFilter()
        }
    }

    // MARK: - Dependencies

    private let logService: LogServiceProtocol

    // MARK: - Initializer

    init(logService: LogServiceProtocol = Dependencies.shared.logService) {
        self.logService = logService
    }

    // MARK: - Public API

    /// Loads all logs from persistence, sorted by most recent first.
    func loadLogs() async {
        isLoading = true

        let allLogs = logService.getAll()
        logs = allLogs.sorted { $0.dateTime > $1.dateTime }

        applyFilter()
        isLoading = false
    }

    /// Deletes all logs from persistence and clears local state.
    func clearAllLogs() {
        _ = logService.deleteAll()
        logs.removeAll()
        filteredLogs.removeAll()
    }

    /// Returns all currently filtered logs as a formatted text block.
    /// Used for sharing.
    func shareText() -> String {
        filteredLogs
            .map { log in
                return "[\(log.dateTime.asFormattedString())] [\(log.context)] [\(log.type)] \(log.message)"
            }
            .joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Applies the selected type filter to the loaded logs.
    private func applyFilter() {
        filteredLogs = logs.filter { $0.type == selectedType }
    }
}
