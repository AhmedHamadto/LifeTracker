import Foundation
import os.log

// MARK: - Log Level

enum LogLevel: Int, Comparable, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    var prefix: String {
        switch self {
        case .debug: return "[DEBUG]"
        case .info: return "[INFO]"
        case .warning: return "[WARNING]"
        case .error: return "[ERROR]"
        case .critical: return "[CRITICAL]"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Log Category

enum LogCategory: String {
    case app = "App"
    case data = "Data"
    case network = "Network"
    case sync = "Sync"
    case health = "Health"
    case documents = "Documents"
    case medications = "Medications"
    case inventory = "Inventory"
    case notifications = "Notifications"
    case vision = "Vision"
    case barcode = "Barcode"
    case ui = "UI"

    var subsystem: String {
        "com.lifetracker.\(rawValue.lowercased())"
    }
}

// MARK: - Log Entry

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: String
    let category: String
    let message: String
    let file: String
    let function: String
    let line: Int
    let metadata: [String: String]?

    init(
        level: LogLevel,
        category: LogCategory,
        message: String,
        file: String,
        function: String,
        line: Int,
        metadata: [String: String]? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level.prefix
        self.category = category.rawValue
        self.message = message
        self.file = (file as NSString).lastPathComponent
        self.function = function
        self.line = line
        self.metadata = metadata
    }

    var formattedMessage: String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = dateFormatter.string(from: self.timestamp)
        return "\(timestamp) \(level) [\(category)] \(message) (\(file):\(line))"
    }
}

// MARK: - Logger

final class Logger {
    static let shared = Logger()

    private let queue = DispatchQueue(label: "com.lifetracker.logging", qos: .utility)
    private var loggers: [LogCategory: os.Logger] = [:]
    private var logHistory: [LogEntry] = []
    private let maxHistorySize = 1000

    #if DEBUG
    var minimumLevel: LogLevel = .debug
    #else
    var minimumLevel: LogLevel = .info
    #endif

    var isEnabled: Bool = true

    private init() {
        // Pre-create loggers for all categories
        for category in LogCategory.allCases {
            loggers[category] = os.Logger(subsystem: category.subsystem, category: category.rawValue)
        }
    }

    // MARK: - Logging Methods

    func debug(
        _ message: String,
        category: LogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        category: LogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        category: LogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        category: LogCategory = .app,
        error: Error? = nil,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(.error, fullMessage, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    func critical(
        _ message: String,
        category: LogCategory = .app,
        error: Error? = nil,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(.critical, fullMessage, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    // MARK: - Core Log Method

    private func log(
        _ level: LogLevel,
        _ message: String,
        category: LogCategory,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        guard isEnabled, level >= minimumLevel else { return }

        let entry = LogEntry(
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line,
            metadata: metadata
        )

        queue.async { [weak self] in
            self?.writeLog(entry, level: level, category: category)
        }
    }

    private func writeLog(_ entry: LogEntry, level: LogLevel, category: LogCategory) {
        // Add to history
        logHistory.append(entry)
        if logHistory.count > maxHistorySize {
            logHistory.removeFirst(logHistory.count - maxHistorySize)
        }

        // Log to system
        if let logger = loggers[category] {
            logger.log(level: level.osLogType, "\(entry.formattedMessage)")
        }

        #if DEBUG
        print(entry.formattedMessage)
        #endif
    }

    // MARK: - History Access

    func getHistory(level: LogLevel? = nil, category: LogCategory? = nil, limit: Int = 100) -> [LogEntry] {
        var filtered = logHistory

        if let level = level {
            filtered = filtered.filter { $0.level == level.prefix }
        }

        if let category = category {
            filtered = filtered.filter { $0.category == category.rawValue }
        }

        return Array(filtered.suffix(limit))
    }

    func clearHistory() {
        queue.async { [weak self] in
            self?.logHistory.removeAll()
        }
    }

    // MARK: - Export

    func exportLogs() -> String {
        logHistory.map { $0.formattedMessage }.joined(separator: "\n")
    }

    func exportLogsAsJSON() -> Data? {
        try? JSONEncoder().encode(logHistory)
    }
}

// MARK: - LogCategory CaseIterable

extension LogCategory: CaseIterable {
    static var allCases: [LogCategory] = [
        .app, .data, .network, .sync, .health,
        .documents, .medications, .inventory,
        .notifications, .vision, .barcode, .ui
    ]
}

// MARK: - Convenience Functions

func logDebug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, error: Error? = nil, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, category: category, error: error, file: file, function: function, line: line)
}

// MARK: - Performance Logging

final class PerformanceLogger {
    private let name: String
    private let startTime: CFAbsoluteTime
    private let category: LogCategory

    init(_ name: String, category: LogCategory = .app) {
        self.name = name
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
        logDebug("[\(name)] Started", category: category)
    }

    func checkpoint(_ label: String) {
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        logDebug("[\(name)] \(label): \(String(format: "%.2f", elapsed))ms", category: category)
    }

    func finish() {
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        logInfo("[\(name)] Completed in \(String(format: "%.2f", elapsed))ms", category: category)
    }
}

func measurePerformance<T>(_ name: String, category: LogCategory = .app, operation: () throws -> T) rethrows -> T {
    let perf = PerformanceLogger(name, category: category)
    defer { perf.finish() }
    return try operation()
}

func measurePerformance<T>(_ name: String, category: LogCategory = .app, operation: () async throws -> T) async rethrows -> T {
    let perf = PerformanceLogger(name, category: category)
    defer { perf.finish() }
    return try await operation()
}
