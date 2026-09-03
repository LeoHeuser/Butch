//
//  PaywallRequest.swift
//  ButchKit
//
//  Created by Leo Heuser on 03.09.26.
//

import Foundation

/// One presentation of the paywall. `PaywallService.presentedRequest` holds the current one; the
/// root sheet is bound to it.
///
/// A fresh identifier per request, so presenting from the same source twice in a row still
/// presents twice.
public struct PaywallRequest: Identifiable, Sendable, Equatable {
    public let id = UUID()
    /// The app's name for where the user hit the lock. Carried on every ``PaywallEvent``.
    public let source: String
}
