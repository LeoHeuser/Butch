//
//  PaywallView.swift
//  ButchKit
//
//  Created by Leo Heuser on 03.09.26.
//

import StoreKit
import SwiftUI

/// The paywall sheet: marketing pages over Apple's `SubscriptionStoreView`. Presented only by the
/// root modifier, never by app code; see ``PaywallService/present(source:)``.
struct PaywallView: View {
    let request: PaywallRequest

    @Environment(PaywallService.self) private var paywall
    @State private var showsPurchaseFailedAlert = false

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: paywall.configuration.subscriptionGroupID, visibleRelationships: .all) {
                PaywallMarketingContent(features: paywall.features)
            }
            // Apple's cancellation button shrinks the content container, banding the full-bleed
            // photos off at the top. The toolbar button below does the same job without the inset.
            .storeButton(.hidden, for: .cancellation)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(paywall.configuration.hasPolicies ? .visible : .hidden, for: .policies)
            .subscriptionStoreButtonLabel(.action)
            .subscriptionStoreControlStyle(.buttons)
            .policyDestination(for: .privacyPolicy, url: paywall.configuration.privacyPolicyURL, title: "webView.privacyPolicy.title")
            .policyDestination(for: .termsOfService, url: paywall.configuration.termsOfServiceURL, title: "webView.termsOfUse.title")
            .onInAppPurchaseStart { _ in
                paywall.report(.purchaseStarted(source: request.source))
            }
            .onInAppPurchaseCompletion { _, result in
                handlePurchaseCompletion(result)
            }
            .alert("error.paywall.purchaseFailed.title", isPresented: $showsPurchaseFailedAlert) {
            } message: {
                Text("error.paywall.purchaseFailed.message")
            }
            .onChange(of: paywall.hasSubscription) { _, isActive in
                // Covers purchase, restore and renewal alike: a restore never reaches
                // onInAppPurchaseCompletion, it arrives through Transaction.updates.
                if isActive {
                    paywall.dismissPaywall()
                }
            }
            .ignoresSafeArea(edges: .top)
            #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .sheetDismissButton()
        }
        // The marketing pages put uncolored text on full-bleed photos shot for a dark ground,
        // so the paywall stays dark regardless of the device appearance.
        .preferredColorScheme(.dark)
        // Outside the NavigationStack, so pushing a policy destination cannot fire this twice.
        // This is the funnel's denominator: without it the purchase count has no reference.
        .onAppear {
            paywall.report(.presented(source: request.source))
        }
    }

    private func handlePurchaseCompletion(_ result: Result<Product.PurchaseResult, any Error>) {
        switch result {
        case .success(let purchaseResult):
            switch purchaseResult {
            case .success:
                // Only this path is a fresh purchase from the paywall, and only here is the
                // source known. A free trial start runs through here too.
                paywall.report(.purchaseCompleted(source: request.source))
                paywall.handleSuccessfulPurchase()
            case .pending:
                // Ask to Buy: Apple's UI informs the user, so no app-side alert. The later
                // approval arrives through Transaction.updates.
                paywall.report(.purchasePending(source: request.source))
            case .userCancelled:
                break
            @unknown default:
                break
            }
        case .failure(let error):
            // Backing out of the Apple ID or confirmation sheet is thrown, not returned as
            // `.userCancelled`. Not a failure, so neither the alert nor the funnel sees it.
            if case StoreKitError.userCancelled = error { return }
            paywall.report(.purchaseFailed(source: request.source, reason: error.localizedDescription))
            showsPurchaseFailedAlert = true
        }
    }
}

private extension View {
    /// Attaches a policy destination only when the app configured a URL for it.
    @ViewBuilder
    func policyDestination(for policy: SubscriptionStorePolicyKind, url: String?, title: LocalizedStringKey) -> some View {
        if let url {
            subscriptionStorePolicyDestination(for: policy) {
                NavigationStack {
                    StaticWebView(url, navigationTitle: title)
                }
            }
        } else {
            self
        }
    }
}

// The subscription button loads from `ButchKitPreview.storekit` when that file is selected as
// the scheme's StoreKit configuration. Without it Apple's store view stays in its loading state.
#Preview("With photos") {
    PaywallView(request: PaywallRequest(source: "preview"))
        .environment(PaywallService(configuration: .preview, features: .previewFeatures))
}

#Preview("Text only") {
    PaywallView(request: PaywallRequest(source: "preview"))
        .environment(PaywallService(configuration: .preview, features: .previewFeaturesWithoutPhotos))
}

// All four page shapes in one set, so the jump between the two layouts is visible while swiping.
#Preview("Mixed") {
    PaywallView(request: PaywallRequest(source: "preview"))
        .environment(PaywallService(configuration: .preview, features: .previewFeaturesMixed))
}
