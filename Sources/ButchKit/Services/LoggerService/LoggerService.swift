//
//  LoggerService.swift
//  ButchKit
//
//  Created by Leo Heuser on 04.08.26.
//

import Foundation
import OSLog

/// Binds a group of loggers to one subsystem.
///
/// Most code never names this type. To declare a category, ask `Logger` for one —
/// `Logger(category:)` resolves the subsystem for you:
///
/// ```swift
/// // LoggerCategories.swift
/// nonisolated extension Logger {
///     /// Capture session, recording lifecycle, and saving to Photos.
///     static let camera = Logger(category: "Camera")
///     /// Audio session configuration and microphone selection.
///     static let audio  = Logger(category: "Audio")
/// }
/// ```
///
/// The service exists for the cases where the subsystem is not the target's own: an app extension
/// filing under its host app, a test writing into a subsystem nothing else touches, and
/// ``LogExport`` and ``LogMirror``, which filter by subsystem and so have to be told which one to
/// read.
///
/// ```swift
/// let host = LoggerService(subsystem: "com.host.app")
/// host["Camera"].notice("Recording started")
/// let report = try await LogExport.text(since: .now.addingTimeInterval(-3600), from: host)
/// ```
///
/// It is also the value behind `EnvironmentValues.log`, which is how a view reaches a logger
/// without a static.
///
/// A service is a value, not a shared instance: `LoggerService()` is cheap, constructing two of
/// them costs nothing, and two with the same subsystem are equal. There is nothing to configure at
/// launch and no bootstrap step that could be missed.
///
/// ## Why it hands back a real `os.Logger`
///
/// The service does not wrap `os.Logger`, it hands you the real thing. That is deliberate: privacy
/// annotations (`privacy: .public`) and lazy formatting only work on `os.Logger`'s own string
/// interpolation. Any wrapper taking a plain `String` would eagerly build the message and log
/// every value in the clear.
///
/// See `Documentation/LoggingStrategy.md` for what to log, at which level, and how to word it.
/// `Equatable` because the service lives in `EnvironmentValues`: SwiftUI uses `==` for change
/// detection when it is available, and comparing one string beats the generic fallback.
public struct LoggerService: Sendable, Equatable {
    /// The subsystem all loggers from this service are created with.
    public let subsystem: String

    /// Creates a service.
    ///
    /// - Parameter subsystem: The subsystem to log under. Defaults to the target's own bundle
    ///   identifier, which is the right choice for an app. Pass a value only when a target should
    ///   log under a different subsystem than its own bundle — for example an app extension that
    ///   belongs to a host app.
    public init(subsystem: String? = nil) {
        self.subsystem = subsystem ?? Self.defaultSubsystem
    }

    /// A logger for the given category.
    ///
    /// Hold the result in a `let` rather than calling this inside a loop. The subscript runs
    /// before the runtime checks whether the level is enabled, so a per-frame
    /// `service["Camera"].debug(…)` pays for a logger it then throws away.
    public subscript(_ category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.name)
    }

    /// The subsystem a target logs under when it does not name one: its own bundle identifier.
    ///
    /// Bundles without an identifier — a command-line tool, a test bundle without a host app —
    /// fall back to the process name, so the logs still belong to the program that wrote them
    /// rather than to ButchKit.
    ///
    /// Resolved once. The unified logging system keeps one object per subsystem and category
    /// forever, so a subsystem that changed mid-process would leave unreachable entries behind.
    static let defaultSubsystem: String =
        Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
}
