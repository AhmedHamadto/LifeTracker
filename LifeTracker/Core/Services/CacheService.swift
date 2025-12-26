import Foundation

/// Manages in-memory and disk caching for offline access
final class CacheService {
    static let shared = CacheService()

    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let queue = DispatchQueue(label: "com.lifetracker.cache", attributes: .concurrent)

    // Cache configuration
    var memoryCacheLimit: Int = 50 * 1024 * 1024 // 50 MB
    var diskCacheLimit: Int = 200 * 1024 * 1024 // 200 MB
    var defaultExpiration: TimeInterval = 60 * 60 * 24 * 7 // 7 days

    private init() {
        // Set up cache directory
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("LifeTrackerCache", isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache
        memoryCache.totalCostLimit = memoryCacheLimit

        logInfo("Cache service initialized at \(cacheDirectory.path)", category: .data)
    }

    // MARK: - Cache Entry

    class CacheEntry: NSObject {
        let data: Data
        let expirationDate: Date
        let metadata: [String: String]?

        var isExpired: Bool {
            Date() > expirationDate
        }

        init(data: Data, expirationDate: Date, metadata: [String: String]? = nil) {
            self.data = data
            self.expirationDate = expirationDate
            self.metadata = metadata
        }
    }

    // MARK: - Store

    func store(_ data: Data, forKey key: String, expiration: TimeInterval? = nil, metadata: [String: String]? = nil) {
        let expirationDate = Date().addingTimeInterval(expiration ?? defaultExpiration)
        let entry = CacheEntry(data: data, expirationDate: expirationDate, metadata: metadata)

        // Store in memory
        memoryCache.setObject(entry, forKey: key as NSString, cost: data.count)

        // Store to disk asynchronously
        queue.async(flags: .barrier) { [weak self] in
            self?.storeToDisk(entry, forKey: key)
        }

        logDebug("Cached \(data.count) bytes for key: \(key)", category: .data)
    }

    func store<T: Encodable>(_ object: T, forKey key: String, expiration: TimeInterval? = nil) {
        do {
            let data = try JSONEncoder().encode(object)
            store(data, forKey: key, expiration: expiration)
        } catch {
            logError("Failed to encode object for caching", error: error, category: .data)
        }
    }

    private func storeToDisk(_ entry: CacheEntry, forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)

        let container = DiskCacheContainer(
            data: entry.data,
            expirationDate: entry.expirationDate,
            metadata: entry.metadata
        )

        do {
            let encoded = try JSONEncoder().encode(container)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            logError("Failed to write cache to disk", error: error, category: .data)
        }
    }

    // MARK: - Retrieve

    func retrieve(forKey key: String) -> Data? {
        // Check memory cache first
        if let entry = memoryCache.object(forKey: key as NSString) {
            if entry.isExpired {
                remove(forKey: key)
                return nil
            }
            logDebug("Cache hit (memory) for key: \(key)", category: .data)
            return entry.data
        }

        // Check disk cache
        return queue.sync {
            retrieveFromDisk(forKey: key)
        }
    }

    func retrieve<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = retrieve(forKey: key) else { return nil }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            logError("Failed to decode cached object", error: error, category: .data)
            return nil
        }
    }

    private func retrieveFromDisk(forKey key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let encoded = try Data(contentsOf: fileURL)
            let container = try JSONDecoder().decode(DiskCacheContainer.self, from: encoded)

            if Date() > container.expirationDate {
                try? fileManager.removeItem(at: fileURL)
                logDebug("Cache expired for key: \(key)", category: .data)
                return nil
            }

            // Restore to memory cache
            let entry = CacheEntry(
                data: container.data,
                expirationDate: container.expirationDate,
                metadata: container.metadata
            )
            memoryCache.setObject(entry, forKey: key as NSString, cost: container.data.count)

            logDebug("Cache hit (disk) for key: \(key)", category: .data)
            return container.data
        } catch {
            logError("Failed to read cache from disk", error: error, category: .data)
            return nil
        }
    }

    // MARK: - Remove

    func remove(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)

        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let fileURL = self.cacheDirectory.appendingPathComponent(key.sha256Hash)
            try? self.fileManager.removeItem(at: fileURL)
        }

        logDebug("Removed cache for key: \(key)", category: .data)
    }

    func removeAll() {
        memoryCache.removeAllObjects()

        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }

        logInfo("Cleared all cache", category: .data)
    }

    // MARK: - Expiration Cleanup

    func cleanupExpired() {
        queue.async(flags: .barrier) { [weak self] in
            self?.performCleanup()
        }
    }

    private func performCleanup() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        var removedCount = 0

        for fileURL in files {
            do {
                let encoded = try Data(contentsOf: fileURL)
                let container = try JSONDecoder().decode(DiskCacheContainer.self, from: encoded)

                if Date() > container.expirationDate {
                    try fileManager.removeItem(at: fileURL)
                    removedCount += 1
                }
            } catch {
                // Remove corrupted cache files
                try? fileManager.removeItem(at: fileURL)
                removedCount += 1
            }
        }

        if removedCount > 0 {
            logInfo("Cleaned up \(removedCount) expired cache entries", category: .data)
        }
    }

    // MARK: - Cache Size

    var diskCacheSize: Int {
        queue.sync {
            calculateDiskCacheSize()
        }
    }

    private func calculateDiskCacheSize() -> Int {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return files.reduce(0) { total, fileURL in
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
    }

    func trimDiskCacheIfNeeded() {
        queue.async(flags: .barrier) { [weak self] in
            self?.performTrim()
        }
    }

    private func performTrim() {
        guard calculateDiskCacheSize() > diskCacheLimit else { return }

        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }

        // Sort by modification date (oldest first)
        let sortedFiles = files.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 < date2
        }

        // Remove files until under limit
        var currentSize = calculateDiskCacheSize()
        var removedCount = 0

        for fileURL in sortedFiles {
            guard currentSize > diskCacheLimit else { break }

            let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            try? fileManager.removeItem(at: fileURL)
            currentSize -= fileSize
            removedCount += 1
        }

        logInfo("Trimmed \(removedCount) cache files to stay under limit", category: .data)
    }
}

// MARK: - Disk Cache Container

private struct DiskCacheContainer: Codable {
    let data: Data
    let expirationDate: Date
    let metadata: [String: String]?
}

// MARK: - String Hash Extension

private extension String {
    var sha256Hash: String {
        let data = Data(utf8)
        var hash = [UInt8](repeating: 0, count: 32)

        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// CommonCrypto import for SHA256
import CommonCrypto
