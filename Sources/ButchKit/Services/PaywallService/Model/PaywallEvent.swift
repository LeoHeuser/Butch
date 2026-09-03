//
//  PaywallEvent.swift
//  ButchKit
//
//  Created by Leo Heuser on 03.09.26.
//

/// The paywall funnel, as it happens.
///
/// ButchKit has no analytics dependency. Assign `PaywallService.onEvent` once and forward each
/// event to whatever the app uses:
///
/// ```swift
/// paywall.onEvent = { event in
///     switch event {
///     case .presented(let source):
///         TelemetryDeck.signal("paywall.presented", parameters: ["paywall.trigger": source])
///     // …
///     }
/// }
/// ```
///
/// `source` is the app's own name for where the user hit the lock ("newScript", "settings"), the
/// value passed to `PaywallService.present(source:)` or `require(source:_:)`.
public enum PaywallEvent: Sendable, Equatable {
    /// The paywall appeared. The funnel's denominator.
    case presented(source: String)
    /// The user tapped a subscribe button and the App Store sheet is about to show.
    case purchaseStarted(source: String)
    /// A fresh purchase from the paywall went through. A free trial start counts too. Restores
    /// and renewals arrive through `Transaction.updates` and are deliberately not reported here.
    case purchaseCompleted(source: String)
    /// Ask to Buy: the purchase waits for approval. The later approval never reaches the paywall.
    case purchasePending(source: String)
    /// The purchase failed. `reason` is the error's localized description. A user backing out
    /// of the App Store sheet is not a failure and is not reported.
    case purchaseFailed(source: String, reason: String)
    /// A transaction from the App Store failed verification and was not finished.
    case verificationFailed
}
