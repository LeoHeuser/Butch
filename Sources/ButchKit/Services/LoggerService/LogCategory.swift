//
//  LogCategory.swift
//  ButchKit
//
//  Created by Leo Heuser on 04.08.26.
//

import Foundation

/// The area of an app a log message belongs to, for example `"Camera"` or `"Purchase"`.
///
/// A category is what you filter by in the Xcode console and in the Console app. It replaces
/// textual prefixes like `[CAM]`, because the system filters by category natively.
///
/// ButchKit ships no predefined categories on purpose. Create one when an area actually logs,
/// not in advance, and keep them all in one file — `LoggerCategories.swift` — with a doc comment
/// saying what each one covers:
///
/// ```swift
/// // LoggerCategories.swift
/// nonisolated extension Logger {
///     /// Capture session, recording lifecycle, and saving to Photos.
///     static let camera = LoggerService.shared["Camera"]
/// }
/// ```
///
/// Categories can also be declared as named values, which gives autocompletion when reading
/// the logger from the SwiftUI environment:
///
/// ```swift
/// nonisolated extension LogCategory {
///     /// Capture session, recording lifecycle, and saving to Photos.
///     static let camera: Self = "Camera"
/// }
///
/// log[.camera].notice("Recording started")
/// ```
public struct LogCategory: Hashable, Sendable, ExpressibleByStringLiteral {
    /// The category name as it appears in the console.
    public let name: String

    public init(_ name: String) {
        self.name = name
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }
}
