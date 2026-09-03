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

    private let autoAdvanceInterval: TimeInterval = 5
    private let userInteractionCooldown: TimeInterval = 15
    // SubscriptionStoreView insets its marketing content; this pulls the photos back to the edges.
    private let negativeHorizontalPadding: CGFloat = -16

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

/// One page: title and description at the bottom, the photo fading out behind them.
struct PaywallFeaturePage: View {
    let feature: PayWallFeature

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text(feature.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(feature.description)
                    .font(.headline)
            }
            .multilineTextAlignment(.center)
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 32)
        .background {
            PaywallBackgroundImage(image: feature.image)
        }
    }
}

/// A full-bleed photo masked by a gradient over its lower part, so text stays legible on it.
struct PaywallBackgroundImage: View {
    var image: ImageResource
    var gradientHeight: CGFloat = 0.62

    var body: some View {
        GeometryReader { proxy in
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 1 - gradientHeight),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
    }
}
