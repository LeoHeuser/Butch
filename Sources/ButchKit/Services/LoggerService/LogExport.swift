//
//  LogExport.swift
//  ButchKit
//
//  Created by Leo Heuser on 04.08.26.
//

import Foundation
import OSLog

/// The importance of a log message, mirroring the levels of `os.Logger`.
public enum LogLevel: String, Sendable {
    case debug
    case info
    case notice
    case error
    case fault

    /// Maps a level read back from the log store.
    ///
    /// Anything the system reports as undefined becomes `notice`, which is the level it uses for
    /// messages logged without an explicit one. Nothing is dropped — a message missing from a
    /// bug report is worse than one carrying a default level.
    init(_ level: OSLogEntryLog.Level) {
        switch level {
        case .debug: self = .debug
        case .info: self = .info
        case .error: self = .error
        case .fault: self = .fault
        default: self = .notice
        }
    }
}

/// What can go wrong while exporting.
public enum LogExportError: Error, LocalizedError {
    /// Nothing matched the requested window.
    ///
    /// The common causes are benign and worth telling the user about rather than handing them an
    /// empty file: the app was relaunched, so the previous session's messages are out of reach,
    /// or the target logs under a different subsystem than the one being read.
    case noEntries

    public var errorDescription: String? {
        switch self {
        case .noEntries:
            "No log messages were found for this period."
        }
    }
}

/// A single log message read back from the system.
public struct LogEntry: Sendable, Identifiable {
    public let date: Date
    public let category: String
    public let level: LogLevel
    public let message: String

    /// Where this entry sat in the read it came from, oldest first.
    ///
    /// Identity here is relative to a read, not durable: the store exposes no record key, and
    /// content cannot stand in for one. The system's timestamp is coarser than the rate an app can
    /// log at, so a repeated message — which the strategy actively encourages, since the text stem
    /// stays constant — yields several entries identical in every field. The position separates
    /// them, and reading the same window again puts them back in the same order.
    public let id: Int

    public init(date: Date, category: String, level: LogLevel, message: String, id: Int) {
        self.date = date
        self.category = category
        self.level = level
        self.message = message
        self.id = id
    }
}

/// Reads this app's own log messages back from the system, for example to attach them to a
/// bug report.
///
/// ```swift
/// let url = try await LogExport.fileURL(since: .now.addingTimeInterval(-3600))
/// ShareLink("Share diagnostics", item: url)
/// ```
///
/// Use ``fileURL(since:from:)`` when the log is going somewhere — it arrives as a proper
/// attachment. ``text(since:from:)`` returns the same content as a string for showing on screen,
/// and ``entries(since:from:)`` returns structured values to filter or list.
///
/// ## What you get, and what you don't
///
/// Two limits are worth knowing before building a feature on this:
///
/// - **Only the running launch.** The system scopes this to the current process. After the app
///   is relaunched the process is a different one, so messages from before a crash are out of
///   reach. Sending logs *while* a bug is happening works; sending them *after* a crash does not.
/// - **`debug` and `info` are usually gone.** Those levels live in an in-memory buffer and are
///   not written to disk. Expect `notice`, `error` and `fault` to be the levels that survive.
///
/// Together they sharpen the most important rule in `Documentation/LoggingStrategy.md`: anything you may need
/// later has to be logged at `notice` or above.
///
/// Every entry point is `@concurrent`, so none of this work can land on the caller's actor. A read
/// takes on the order of a second even on a fast machine — plan for a progress state, not an
/// instant tap.
public enum LogExport {
    /// Reads log entries written since the given date.
    ///
    /// Enumerating the log store is the expensive part, and it stops promptly if the calling task
    /// is cancelled.
    ///
    /// - Parameters:
    ///   - date: How far back to read.
    ///   - service: The service whose subsystem to filter by. Pass the same service you log
    ///     with; the default matches the default logging path.
    /// - Returns: The matching entries, oldest first.
    @concurrent
    public static func entries(
        since date: Date,
        from service: LoggerService = .shared
    ) async throws -> [LogEntry] {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: date)
        let predicate = NSPredicate(format: "subsystem == %@", service.subsystem)

        var entries: [LogEntry] = []
        for entry in try store.getEntries(with: [], at: position, matching: predicate) {
            try Task.checkCancellation()
            guard let entry = entry as? OSLogEntryLog else { continue }
            entries.append(
                LogEntry(
                    date: entry.date,
                    category: entry.category,
                    level: LogLevel(entry.level),
                    message: entry.composedMessage,
                    id: entries.count
                )
            )
        }
        return entries
    }

    /// Reads log entries since the given date and renders them as plain text, one line each.
    ///
    /// Each line reads `<timestamp> [<level>] [<category>] <message>`, which is what you want in
    /// an email or a shared file. A message that itself contains line breaks is flattened, with
    /// each break written as a literal `\n`, so one record always stays one line.
    ///
    /// To hand the log to a share sheet, use ``fileURL(since:from:)`` instead — sharing a string
    /// pastes it into the message body, sharing a file attaches it.
    @concurrent
    public static func text(
        since date: Date,
        from service: LoggerService = .shared
    ) async throws -> String {
        render(try await entries(since: date, from: service))
    }

    /// Renders entries as the one-line-per-record text both `text` and `fileURL` hand out.
    private static func render(_ entries: [LogEntry]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return entries
            .map { entry in
                let message = entry.message
                    .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                    .joined(separator: #"\n"#)
                return "\(formatter.string(from: entry.date)) [\(entry.level.rawValue)] [\(entry.category)] \(message)"
            }
            .joined(separator: "\n")
    }

    /// Writes the log to a plain text file and returns its URL, ready to hand to a `ShareLink`.
    ///
    /// The file is named `<AppName>-Diagnostics-<date>-<time>-<id>.txt` so it reads as something
    /// meaningful in a mailbox rather than as an anonymous temporary file. The app name comes
    /// from the bundle — nothing to configure.
    ///
    /// Every call writes a new file into the temporary directory, so two shares can be open at
    /// once without one overwriting the other. **The file is yours to delete** once the share
    /// sheet is done with it; the system clears the temporary directory eventually, but not
    /// promptly and not on a schedule you can rely on.
    ///
    /// - Parameters:
    ///   - date: How far back to read.
    ///   - service: The service whose subsystem to filter by. Pass the same service you log with.
    /// - Returns: A file URL in the temporary directory.
    /// - Throws: ``LogExportError/noEntries`` when nothing matched, rather than handing back an
    ///   empty file. Surface that to the user — an empty attachment looks like a real report.
    @concurrent
    public static func fileURL(
        since date: Date,
        from service: LoggerService = .shared
    ) async throws -> URL {
        let entries = try await entries(since: date, from: service)
        guard !entries.isEmpty else { throw LogExportError.noEntries }

        // UTC, to match the timestamps inside the file. A filename in the device's local time
        // would contradict its own contents by up to a day for users far from GMT.
        let stamp = DateFormatter()
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.timeZone = TimeZone(identifier: "UTC")
        stamp.dateFormat = "yyyy-MM-dd-HHmm"

        let name = "\(appName)-Diagnostics-\(stamp.string(from: Date()))-\(UUID().uuidString.prefix(8)).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)

        try render(entries).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// The app's own name, read from its bundle, reduced to characters that behave in a file name.
    ///
    /// Falls back through the name shown under the app icon, the bundle name, and finally the
    /// process name, so a command-line tool or a test bundle still gets something meaningful.
    /// Deliberately reads the non-localized value: a support inbox is easier to work with when
    /// every user's report carries the same app name, whatever language they run the app in.
    private static let appName: String = {
        [
            Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String,
            Bundle.main.infoDictionary?["CFBundleName"] as? String,
            ProcessInfo.processInfo.processName
        ]
        .lazy
        .compactMap { $0?.filter { $0.isLetter || $0.isNumber } }
        .first { !$0.isEmpty } ?? "App"
    }()
}
