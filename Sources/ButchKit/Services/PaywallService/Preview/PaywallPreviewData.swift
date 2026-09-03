//
//  PaywallPreviewData.swift
//  ButchKit
//
//  Created by Leo Heuser on 03.09.26.
//

import SwiftUI

extension PaywallConfiguration {
    /// Points at the subscription group in `ButchKitPreview.storekit`, next to this file. Select it as
    /// the scheme's StoreKit configuration and the paywall preview loads a real product.
    static let preview = PaywallConfiguration(subscriptionGroupID: "B07C4A12")
}

extension ImageResource {
    /// The placeholders in `PaywallPreviewAssets.xcassets`, standing in for an app's own photos.
    /// Only Xcode compiles the catalog, so these resolve in previews and nowhere else.
    static func previewPhoto(_ index: Int) -> ImageResource {
        ImageResource(name: "PaywallPreview\(index)", bundle: .module)
    }
}

extension PayWallFeature {
    /// The four shapes a page can take. Every preview in the module draws from these, so the
    /// sample copy lives in one place. Computed rather than stored: `PayWallFeature` is not
    /// `Sendable`, which a static constant would require.
    static var previewFull: PayWallFeature {
        PayWallFeature(
            title: "Write without limits",
            description: "Unlimited scripts, scenes and characters.",
            image: .previewPhoto(1)
        )
    }

    static var previewWithoutDescription: PayWallFeature {
        PayWallFeature(title: "Everywhere you are", image: .previewPhoto(2))
    }

    static var previewWithoutPhoto: PayWallFeature {
        PayWallFeature(
            title: "Export like a pro",
            description: "Industry-standard PDF and Final Draft files in one tap."
        )
    }

    static var previewTitleOnly: PayWallFeature {
        PayWallFeature(title: "One subscription, every device")
    }
}

extension [PayWallFeature] {
    /// Three pages with photos, the case an app ships.
    static var previewFeatures: [PayWallFeature] {
        [
            .previewFull,
            PayWallFeature(
                title: "Everywhere you are",
                description: "Your work stays in sync across iPhone, iPad and Mac.",
                image: .previewPhoto(2)
            ),
            PayWallFeature(
                title: "Export like a pro",
                description: "Industry-standard PDF and Final Draft files in one tap.",
                image: .previewPhoto(3)
            )
        ]
    }

    /// The same three pages without photos, for the text-only layout.
    static var previewFeaturesWithoutPhotos: [PayWallFeature] {
        previewFeatures.map { PayWallFeature(title: $0.title, description: $0.description) }
    }

    /// All four page shapes in one swipeable set. Swipe through it to see how the two layouts
    /// sit next to each other.
    static var previewFeaturesMixed: [PayWallFeature] {
        [.previewFull, .previewWithoutDescription, .previewWithoutPhoto, .previewTitleOnly]
    }
}

extension View {
    /// The dark ground the paywall forces on itself, so a preview shows a page as the paywall does.
    func paywallPreviewGround() -> some View {
        background(.black).preferredColorScheme(.dark)
    }
}
