//
//  PayWallFeature.swift
//  ButchKit
//
//  Created by Leo Heuser on 03.09.26.
//

import SwiftUI

/// One marketing page on the paywall: a full-bleed photo with a title and a line of text.
///
/// Declare the pages once, next to the configuration, and pass them to
/// `View.paywallEnvironment(_:features:)`. The paywall shows them as swipeable pages that
/// advance on their own.
///
/// ```swift
/// let paywallFeatures: [PayWallFeature] = [
///     PayWallFeature(title: "paywall.feature.1.title",
///                    description: "paywall.feature.1.description",
///                    image: .payWallFeature1),
///     PayWallFeature(title: "paywall.feature.2.title",
///                    description: "paywall.feature.2.description",
///                    image: .payWallFeature2),
/// ]
/// ```
///
/// Title and description are keys in the app's own string catalog; the image is an asset from the
/// app's catalog. The photos are shown on a dark ground, so shoot or grade them for that.
public struct PayWallFeature: Identifiable {
    public let id = UUID()
    public let title: LocalizedStringKey
    public let description: LocalizedStringKey
    public let image: ImageResource

    public init(title: LocalizedStringKey, description: LocalizedStringKey, image: ImageResource) {
        self.title = title
        self.description = description
        self.image = image
    }
}
