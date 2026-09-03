//
//  PaywallStatusRow.swift
//  ButchKit
//
//  Created by Leo Heuser on 03.09.26.
//

import StoreKit
import SwiftUI

/// One settings row that says whether the user pays, and leads somewhere either way.
///
/// A subscriber gets the way to the system's own subscription management; everybody else gets
/// the offer. Both are things an app has to have: Apple expects a management path, and a
/// subscriber who cannot find out what they are paying for writes to support instead.
///
/// ```swift
/// Form {
///     Section {
///         PaywallStatusRow(source: "settings")
///     }
/// }
/// ```
///
/// Belongs in a `Form` or a `List`, below the root's `View.paywallEnvironment(_:features:)`.
/// A settings screen presented as a sheet also needs `View.paywallSheet()` on its content,
/// otherwise the paywall has nowhere to appear from.
public struct PaywallStatusRow: View {
    private let source: String

    @Environment(PaywallService.self) private var paywall

    /// Creates the row.
    ///
    /// - Parameter source: The app's name for this entry point, carried on every
    ///   ``PaywallEvent`` the row produces. Conventionally `"settings"`.
    public init(source: String) {
        self.source = source
    }

    public var body: some View {
        // Two rows rather than one row that changes its mind: the states share a place in the
        // form, not a shape. What they have in common is only that they sit here.
        if paywall.hasSubscription {
            SubscribedRow()
        } else {
            UnsubscribedRow(source: source)
        }
    }
}

/// The subscriber's row: what they have, and the way to the system's management for it.
private struct SubscribedRow: View {
    /// Where the App Store keeps subscriptions on the Mac, which has no in-app sheet for them.
    private static let macSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")

    @Environment(\.openURL) private var openURL

    /// Only ever set on iOS. On macOS the button opens the App Store instead and this stays
    /// `false`, because `manageSubscriptionsSheet` does not exist there.
    @State private var managesSubscription = false

    var body: some View {
        LabeledContent("paywall.status.subscribed") {
            Button("button.manageSubscription") {
#if os(iOS)
                managesSubscription = true
#else
                if let url = Self.macSubscriptionsURL { openURL(url) }
#endif
            }
        }
        .manageSubscription(isPresented: $managesSubscription)
    }
}

/// Everybody else's row: the offer, shown rather than demanded.
private struct UnsubscribedRow: View {
    let source: String

    @Environment(PaywallService.self) private var paywall

    var body: some View {
        // `present`, not `require`: the settings sell nothing on their own, so there is no
        // action waiting on the other side of a purchase.
        Button("paywall.status.unsubscribed") {
            paywall.present(source: source)
        }
    }
}

private extension View {
    /// `manageSubscriptionsSheet` is iOS only. Isolated into a `@ViewBuilder` because a `#if`
    /// around the modifier at the call site would fork the row's type between the platforms.
    @ViewBuilder
    func manageSubscription(isPresented: Binding<Bool>) -> some View {
#if os(iOS)
        manageSubscriptionsSheet(isPresented: isPresented)
#else
        self
#endif
    }
}

#Preview("Unsubscribed") {
    Form {
        PaywallStatusRow(source: "preview")
    }
    .environment(PaywallService(configuration: .preview))
}

// The row a subscriber sees, drawn directly. `PaywallStatusRow` picks it by asking StoreKit,
// which a preview cannot answer for, but the row itself reads nothing but its own state.
#Preview("Subscribed") {
    Form {
        SubscribedRow()
    }
}
