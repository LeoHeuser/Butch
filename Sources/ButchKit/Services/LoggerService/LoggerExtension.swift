//
//  LoggerExtension.swift
//  ButchKit
//
//  Created by Leo Heuser on 05.08.26.
//

import Foundation
import OSLog

public extension Logger {
    /// Creates a logger for the given category, under this target's own subsystem.
    ///
    /// This is how an app declares its categories. Keep them all in one file,
    /// `LoggerCategories.swift`, each with a comment saying what it covers:
    ///
    /// ```swift
    /// nonisolated extension Logger {
    ///     /// Capture session, recording lifecycle, and saving to Photos.
    ///     static let camera = Logger(category: "Camera")
    /// }
    ///
    /// Logger.camera.notice("Recording started: fps=\(fps, privacy: .public)")
    /// ```
    ///
    /// `nonisolated` is required once a project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`:
    /// without it the loggers belong to the main actor and cannot be read from a background queue.
    /// One keyword on the extension covers the whole file, and needs Swift 6.1 or newer.
    ///
    /// Declare each logger once, as a `static let`. Creating one runs before the runtime checks
    /// whether the level is enabled, so building a logger per frame pays for one it throws away.
    ///
    /// - Parameters:
    ///   - category: The area of the app these messages belong to.
    ///   - subsystem: Only for a target that must log under a subsystem other than its own bundle,
    ///     for example an app extension filing under its host app. Defaults to the bundle
    ///     identifier — see ``LoggerService/init(subsystem:)``.
    ///
    /// The label order is `category` first, and has to stay that way. Written the other way round
    /// this would collide with `os.Logger`'s own `init(subsystem:category:)`: for a call passing
    /// two string literals the compiler prefers `String` over ``LogCategory``, so
    /// `Logger(subsystem: "…", category: "…")` would silently keep resolving to Apple's
    /// initializer while the same call with an explicit `LogCategory` resolved to this one. Two
    /// identical-looking lines, two different subsystems.
    init(category: LogCategory, subsystem: String? = nil) {
        self.init(
            subsystem: subsystem ?? LoggerService.defaultSubsystem,
            category: category.name
        )
    }
}
