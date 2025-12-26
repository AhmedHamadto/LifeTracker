import Foundation
import SwiftData
import Combine

/// Manages data synchronization with CloudKit
@Observable
final class SyncManager {
    static let shared = SyncManager()

    private(set) var syncState: SyncState = .idle
    private(set) var lastSyncDate: Date?
    private(set) var pendingChangesCount: Int = 0

    private var syncCancellable: AnyCancellable?
    private var networkCancellable: AnyCancellable?

    enum SyncState: Equatable {
        case idle
        case syncing
        case error(String)
        case offline

        var description: String {
            switch self {
            case .idle: return "Up to date"
            case .syncing: return "Syncing..."
            case .error(let message): return "Error: \(message)"
            case .offline: return "Offline"
            }
        }

        var icon: String {
            switch self {
            case .idle: return "checkmark.icloud"
            case .syncing: return "arrow.triangle.2.circlepath.icloud"
            case .error: return "exclamationmark.icloud"
            case .offline: return "icloud.slash"
            }
        }

        var color: String {
            switch self {
            case .idle: return "green"
            case .syncing: return "blue"
            case .error: return "red"
            case .offline: return "gray"
            }
        }
    }

    private init() {
        setupNetworkObserver()
        loadLastSyncDate()
    }

    // MARK: - Setup

    private func setupNetworkObserver() {
        networkCancellable = NotificationCenter.default.publisher(for: .networkBecameAvailable)
            .sink { [weak self] _ in
                Task {
                    await self?.syncIfNeeded()
                }
            }

        // Also observe when going offline
        NotificationCenter.default.addObserver(
            forName: .networkBecameUnavailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncState = .offline
        }
    }

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    private func saveLastSyncDate() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }

    // MARK: - Sync Operations

    func syncIfNeeded() async {
        guard NetworkMonitor.shared.isSuitableForSync else {
            syncState = .offline
            return
        }

        // Check if sync is needed (e.g., more than 5 minutes since last sync)
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < 300 {
            logDebug("Sync not needed - last sync was recent", category: .sync)
            return
        }

        await performSync()
    }

    func forceSync() async {
        guard NetworkMonitor.shared.isConnected else {
            syncState = .offline
            logWarning("Cannot sync - offline", category: .sync)
            return
        }

        await performSync()
    }

    private func performSync() async {
        syncState = .syncing
        logInfo("Starting sync...", category: .sync)

        do {
            // SwiftData with CloudKit handles sync automatically
            // This is where you would trigger any manual sync logic
            try await Task.sleep(for: .milliseconds(500)) // Simulate sync delay

            syncState = .idle
            saveLastSyncDate()
            pendingChangesCount = 0
            logInfo("Sync completed successfully", category: .sync)

            NotificationCenter.default.post(name: .syncCompleted, object: nil)
        } catch {
            syncState = .error(error.localizedDescription)
            logError("Sync failed", error: error, category: .sync)

            NotificationCenter.default.post(
                name: .syncFailed,
                object: nil,
                userInfo: ["error": error]
            )
        }
    }

    // MARK: - Pending Changes

    func markPendingChange() {
        pendingChangesCount += 1
        logDebug("Pending changes: \(pendingChangesCount)", category: .sync)
    }

    func clearPendingChanges() {
        pendingChangesCount = 0
    }

    // MARK: - Status

    var statusDescription: String {
        if syncState == .offline {
            return "Offline - changes will sync when connected"
        }

        if pendingChangesCount > 0 {
            return "\(pendingChangesCount) pending change\(pendingChangesCount == 1 ? "" : "s")"
        }

        if let lastSync = lastSyncDate {
            return "Last synced \(lastSync.relativeDescription)"
        }

        return syncState.description
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let syncCompleted = Notification.Name("syncCompleted")
    static let syncFailed = Notification.Name("syncFailed")
}

// MARK: - Conflict Resolution

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
    case askUser
}

protocol ConflictResolvable {
    var lastModified: Date { get }
    func merge(with remote: Self) -> Self
}

extension SyncManager {
    func resolveConflict<T: ConflictResolvable>(
        local: T,
        remote: T,
        strategy: ConflictResolution = .useRemote
    ) -> T {
        switch strategy {
        case .useLocal:
            logInfo("Conflict resolved: using local", category: .sync)
            return local
        case .useRemote:
            logInfo("Conflict resolved: using remote", category: .sync)
            return remote
        case .merge:
            logInfo("Conflict resolved: merging", category: .sync)
            return local.merge(with: remote)
        case .askUser:
            // Default to most recent for automatic resolution
            logInfo("Conflict resolved: using most recent", category: .sync)
            return local.lastModified > remote.lastModified ? local : remote
        }
    }
}
