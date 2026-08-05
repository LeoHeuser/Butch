//
//  LoggerService.swift
//  ButchKit
//
//  Created by Leo Heuser on 04.08.26.
//

import Foundation
import OSLog

/// Vends `os.Logger` instances for an app, with the subsystem resolved once.
///
/// The service does not wrap `os.Logger`, it hands you the real thing. That is deliberate:
/// privacy annotations (`privacy: .public`) and lazy formatting only work on `os.Logger`'s own
/// string interpolation. Any wrapper taking a plain `String` would eagerly build the message and
/// log every value in the clear.
///
/// ## Setup
///
/// Declare the app's categories in one dedicated file, `LoggerCategories.swift`. That file is the
/// registry: the single place a category comes into existence, and where you say what it covers.
/// There is nothing to call at launch.
///
/// ```swift
/// // LoggerCategories.swift
/// nonisolated extension Logger {
///     /// Capture session, recording lifecycle, and saving to Photos.
///     static let camera = LoggerService.shared["Camera"]
///     /// Audio session configuration and microphone selection.
///     static let audio  = LoggerService.shared["Audio"]
/// }
/// ```
///
/// `nonisolated` is required once a project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`:
/// without it the loggers belong to the main actor and cannot be read from a background queue.
/// One keyword on the extension covers the whole file, and needs Swift 6.1 or newer.
///
/// ## Writing a message
///
/// ```swift
/// Logger.camera.notice("Recording started: fps=\(fps, privacy: .public)")
/// Logger.camera.error("Capture start failed: code=\(code, privacy: .public) op=startRecording")
/// ```
///
/// Interpolated values must be `CustomStringConvertible`. Types like `CGSize` are not, so pass
/// their parts (`width=`, `height=`) or convert with `String(describing:)`.
///
/// Hold the `Logger` in a `let` as shown above rather than calling ``subscript(_:)`` inside a
/// loop. The subscript is evaluated before the runtime checks whether the level is enabled, so a
/// per-frame `LoggerService.shared["Camera"].debug(…)` pays for a logger it then throws away.
///
/// See `Documentation/LoggingStrategy.md` for what to log, at which level, and how to word it.
/// `Equatable` because the service lives in `EnvironmentValues`: SwiftUI uses `==` for change
/// detection when it is available, and comparing one string beats the generic fallback.
public struct LoggerService: Sendable, Equatable {
    /// The subsystem all loggers from this service are created with.
    public let subsystem: String

    /// Creates a service.
    ///
    /// - Parameter subsystem: The subsystem to log under. Defaults to the main bundle
    ///   identifier, which is the right choice for an app. Pass a value only when a target
    ///   should log under a different subsystem than its own bundle — for example an app
    ///   extension that belongs to a host app.
    ///
    /// Bundles without an identifier — a command-line tool, a test bundle without a host app —
    /// fall back to the process name, so the logs still belong to the program that wrote them
    /// rather than to ButchKit.
    public init(subsystem: String? = nil) {
        self.subsystem = subsystem
        ?? Bundle.main.bundleIdentifier
        ?? ProcessInfo.processInfo.processName
    }

    /// A logger for the given category.
    public subscript(_ category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.name)
    }

    /// The process-wide service, using the main bundle identifier as its subsystem.
    ///
    /// Immutable on purpose, so it is safe to read from any isolation domain and there is no
    /// configuration step that could be missed. The unified logging system keeps one object per
    /// subsystem and category forever, so a subsystem that changes mid-process would leave
    /// unreachable entries behind.
    public static let shared = LoggerService()
}
