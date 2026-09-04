//
//  LogMirrorEnvironment.swift
//  ButchKit
//
//  Created by Leo Heuser on 04.09.26.
//

import SwiftUI

private struct LogMirrorKey: EnvironmentKey {
    /// A mirror on the target's own subsystem, the same file `LogMirror()` opens. Nothing
    /// harvests this default on its own; a read through it still starts with a harvest, so a
    /// view that forgot the root modifier gets the current launch and whatever the file held.
    static let defaultValue = LogMirror()
}

public extension EnvironmentValues {
    /// The ``LogMirror`` for this view hierarchy, set by ``SwiftUICore/View/logMirror(_:)``.
    ///
    /// ```swift
    /// @Environment(\.logMirror) private var mirror
    ///
    /// let url = try await mirror.fileURL(since: .now.addingTimeInterval(-7 * 86_400))
    /// ```
    var logMirror: LogMirror {
        get { self[LogMirrorKey.self] }
        set { self[LogMirrorKey.self] = newValue }
    }
}

private struct LogMirrorModifier: ViewModifier {
    let mirror: LogMirror
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .environment(\.logMirror, mirror)
            .onChange(of: scenePhase) { _, phase in
                guard phase == .background else { return }
                mirror.harvestBeforeSuspension()
            }
    }
}

public extension View {
    /// Keeps the log across launches: hands the mirror to the view hierarchy and harvests every
    /// time the scene enters the background.
    ///
    /// Apply once, at the root, with a mirror the app owns:
    ///
    /// ```swift
    /// @main struct MyApp: App {
    ///     @State private var logMirror = LogMirror()
    ///
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .logMirror(logMirror)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// The background harvest is the only automatic one. Reads through the mirror harvest on
    /// their own, so nothing more is needed before an export.
    func logMirror(_ mirror: LogMirror) -> some View {
        modifier(LogMirrorModifier(mirror: mirror))
    }
}
