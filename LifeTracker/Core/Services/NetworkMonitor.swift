import Foundation
import Network
import Combine

/// Monitors network connectivity status
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.lifetracker.networkmonitor")

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false

    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown

        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wiredEthernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    private init() {
        monitor = NWPathMonitor()
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateStatus(path)
            }
        }
        monitor.start(queue: queue)
        logInfo("Network monitor started", category: .network)
    }

    func stop() {
        monitor.cancel()
        logInfo("Network monitor stopped", category: .network)
    }

    private func updateStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }

        // Log status changes
        if wasConnected != isConnected {
            if isConnected {
                logInfo("Network connected via \(connectionType.description)", category: .network)
                NotificationCenter.default.post(name: .networkBecameAvailable, object: nil)
            } else {
                logWarning("Network disconnected", category: .network)
                NotificationCenter.default.post(name: .networkBecameUnavailable, object: nil)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkBecameAvailable = Notification.Name("networkBecameAvailable")
    static let networkBecameUnavailable = Notification.Name("networkBecameUnavailable")
}

// MARK: - Network Condition Check

extension NetworkMonitor {
    /// Returns true if conditions are suitable for sync
    var isSuitableForSync: Bool {
        isConnected && !isConstrained
    }

    /// Returns true if conditions are suitable for large data transfers
    var isSuitableForLargeTransfer: Bool {
        isConnected && !isExpensive && !isConstrained
    }
}
