//
//  NetworkMonitor.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 06/08/25.
//

import Network
import Combine

/// An observable network monitor that observes internet connectivity changes in real time.
///
/// `NetworkMonitor` uses Apple's `NWPathMonitor` to track the current network status and publishes connectivity updates
/// through the `isConnected` property. It's marked with `@MainActor` to ensure UI updates happen on the main thread.
///
/// Use this class when you want your views or view models to react to network availability changes, such as toggling between
/// online and offline modes.
///
/// Example usage:
/// ```swift
/// @StateObject private var networkMonitor = NetworkMonitor()
///
/// var body: some View {
///     Text(networkMonitor.isConnected ? "Online" : "Offline")
/// }
/// ```
@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
