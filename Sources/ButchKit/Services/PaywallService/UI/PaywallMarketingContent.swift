//
//  PaywallMarketingContent.swift
//  ButchKit
//
//  Created by Leo Heuser on 03.09.26.
//

import SwiftUI

/// The swipeable marketing pages above the subscription buttons. Advances on its own every
/// five seconds and pauses for fifteen after the user swipes.
struct PaywallMarketingContent: View {
    let features: [PayWallFeature]
    /// The height of the paywall itself, measured by ``PaywallView``. The pages claim a share of
    /// it as their floor.
    let availableHeight: CGFloat

    private let autoAdvanceInterval: TimeInterval = 5
    private let userInteractionCooldown: TimeInterval = 15
    // SubscriptionStoreView insets its marketing content; this pulls the photos back to the edges.
    private let negativeHorizontalPadding: CGFloat = -16
    // A paged TabView has no height of its own. While SubscriptionStoreView fills the sheet this
    // floor never binds; once it switches to its scrolling layout the pages would otherwise
    // collapse. A share of the paywall's height rather than a point value, so it holds on an iPad
    // or Mac sheet as well as on a phone. It grows downwards from the top: 1 would claim the whole
    // paywall and push the subscription controls past the bottom edge, 0.38 leaves them their room.
    private let minimumPageHeightFraction: CGFloat = 0.38

    private var minimumPageHeight: CGFloat { availableHeight * minimumPageHeightFraction }

    @State private var currentPage = 0
    @State private var isProgrammaticChange = false
    @State private var cooldownEnd: Date = .distantPast

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(features.indices, id: \.self) { index in
                PaywallFeaturePage(feature: features[index])
                    .tag(index)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        #endif
        .frame(minHeight: minimumPageHeight)
        .padding(.horizontal, negativeHorizontalPadding)
        .onChange(of: currentPage) {
            if isProgrammaticChange {
                isProgrammaticChange = false
            } else {
                cooldownEnd = Date().addingTimeInterval(userInteractionCooldown)
            }
        }
        .task {
            // Ends with the view; a page change does not restart the interval.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(autoAdvanceInterval))
                guard features.count > 1, Date() >= cooldownEnd else { continue }
                withAnimation {
                    isProgrammaticChange = true
                    currentPage = (currentPage + 1) % features.count
                }
            }
        }
    }
}

// `availableHeight` stands in for what PaywallView measures on the sheet; roughly a phone.
#Preview("With photos") {
    PaywallMarketingContent(features: .previewFeatures, availableHeight: 800)
        // Stands in for the inset SubscriptionStoreView gives its marketing content.
        .padding(.horizontal, 16)
        .paywallPreviewGround()
}

#Preview("Text only") {
    PaywallMarketingContent(features: .previewFeaturesWithoutPhotos, availableHeight: 800)
        .padding(.horizontal, 16)
        .paywallPreviewGround()
}

#Preview("Mixed") {
    PaywallMarketingContent(features: .previewFeaturesMixed, availableHeight: 800)
        .padding(.horizontal, 16)
        .paywallPreviewGround()
}
