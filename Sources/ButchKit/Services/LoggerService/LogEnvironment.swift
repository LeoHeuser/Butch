//
//  LogEnvironment.swift
//  ButchKit
//
//  Created by Leo Heuser on 04.08.26.
//

import SwiftUI

private struct LoggerServiceKey: EnvironmentKey {
    static let defaultValue = LoggerService.shared
}

public extension EnvironmentValues {
    /// The ``LoggerService`` for this view hierarchy.
    ///
    /// Works without any setup — it defaults to ``LoggerService/shared``:
    ///
    /// ```swift
    /// nonisolated extension LogCategory {
    ///     /// Entitlement checks and paywall decisions.
    ///     static let purchase: Self = "Purchase"
    /// }
    ///
    /// struct PaywallView: View {
    ///     @Environment(\.log) private var log
    ///
    ///     var body: some View {
    ///         PaywallContent()
    ///             .onAppear {
    ///                 log[.purchase].notice("Paywall presented: source=onboarding")
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// The category still belongs in `LoggerCategories.swift` alongside the rest, so it stays
    /// findable — the environment only changes how you reach the logger, not where categories
    /// are declared.
    ///
    /// The environment only exists inside a view body. Services, actors and background queues
    /// use a static logger instead — see ``LoggerService``.
    ///
    /// To point a view hierarchy at a different subsystem, set it like any other environment
    /// value: `.environment(\.log, LoggerService(subsystem: "com.host.app"))`.
    var log: LoggerService {
        get { self[LoggerServiceKey.self] }
        set { self[LoggerServiceKey.self] = newValue }
    }
}
