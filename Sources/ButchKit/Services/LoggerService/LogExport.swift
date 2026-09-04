//
//  LogExport.swift
//  ButchKit
//
//  Created by Leo Heuser on 04.08.26.
//

import Foundation
import OSLog

/// The importance of a log message, mirroring the levels of `os.Logger`.
public enum LogLevel: String, Sendable, Codable {
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

    /// Whether the system writes this level to disk. Only these survive in the field, and only
    /// these are worth keeping across launches — see ``LogMirror``.
    var isPersisted: Bool {
        switch self {
        case .debug, .info: false
        case .notice, .error, .fault: true
        }
    }
}

/// What can go wrong while exporting.
public enum LogExportError: Error, LocalizedError {
    /// Nothing matched the requested window.
    ///
    /// The common causes are benign and worth telling the user about rather than handing them an
    /// empty file: the window is too short, or the target logs under a different subsystem than
    /// the one being read. Without a ``LogMirror`` a relaunch is a cause as well, since the live
    /// store holds the current process only.
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

/// Reads this app's own log messages back from the system, for the current launch only.
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
/// - **Only the running launch.** The system scopes this to the current process. After the app
///   is relaunched the process is a different one, so everything before is out of reach. For a
///   log that survives relaunches, and that is what a user sends days later, use ``LogMirror``;
///   it persists these same entries and offers the same three shapes.
/// - **`debug` is gone, `info` may not be.** `debug` lives in an in-memory buffer and is not
///   handed back. `info` is, for the current process, even though the system never writes it to
///   disk. Expect `notice`, `error` and `fault` to be the levels that matter.
/// - **Everything is in the clear.** A process reading its own log sees values that were
///   interpolated without a privacy annotation as written. Only an explicit `privacy: .private`
///   or `.private(mask: .hash)` comes back redacted. The strategy's rule not to log user data at
///   any level is what protects an export, not the default privacy.
///
/// Every entry point is `@concurrent`, so none of this work can land on the caller's actor. A read
/// takes on the order of a second even on a fast machine, and for this scope the cost does not
/// shrink with the window: the system ignores the requested position and hands back every entry
/// of the process, which is why the date filter is applied here. Plan for a progress state, not
/// an instant tap.
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
        from service: LoggerService = LoggerService()
    ) async throws -> [LogEntry] {
        try await readEntries(since: date, from: service)
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
        from service: LoggerService = LoggerService()
    ) async throws -> String {
        render(try await entries(since: date, from: service))
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
        from service: LoggerService = LoggerService()
    ) async throws -> URL {
        try writeFile(try await entries(since: date, from: service))
    }

    /// The one place the log store is opened. ``LogMirror`` harvests through this as well.
    ///
    /// The date is filtered in code because the store does not do it: for the current-process
    /// scope `position(date:)` is accepted and ignored, and every entry of the process comes back
    /// regardless (measured on macOS 26; the enumeration takes the same second either way).
    @concurrent
    static func readEntries(since date: Date, from service: LoggerService) async throws -> [LogEntry] {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: date)
        let predicate = NSPredicate(format: "subsystem == %@", service.subsystem)

        var entries: [LogEntry] = []
        for entry in try store.getEntries(with: [], at: position, matching: predicate) {
            try Task.checkCancellation()
            guard let entry = entry as? OSLogEntryLog, entry.date >= date else { continue }
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

    /// Renders entries as the one-line-per-record text both `text` and `fileURL` hand out.
    static func render(_ entries: [LogEntry]) -> String {
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

    /// Writes rendered entries to a fresh, meaningfully named file in the temporary directory.
    /// Shared with ``LogMirror`` so both exports look identical in a mailbox.
    static func writeFile(_ entries: [LogEntry]) throws -> URL {
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
