//
//  WebViewButton.swift
//  Butch
//
//  Created by Leo Heuser on 26.05.25.
//

import SwiftUI
import WebKit

// MARK: - Locale.LanguageCode Extension

public extension Locale.LanguageCode {
    static let en = Self("en")
    static let de = Self("de")
}

public struct WebViewButton: View {
    // MARK: - Properties
    let title: LocalizedStringKey
    let systemImage: String?
    let urls: [Locale.LanguageCode: String]
    let fallback: Locale.LanguageCode

    @State private var showingWebView = false
    
    // MARK: - Initializer
    public init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        urls: [Locale.LanguageCode: String],
        fallback: Locale.LanguageCode
    ) {
        self.title = title
        self.systemImage = systemImage
        self.urls = urls
        self.fallback = fallback
    }
    
    // MARK: - View
    public var body: some View {
        Button {
            showingWebView = true
        } label: {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .sheet(isPresented: $showingWebView) {
            StaticWebView(title, urls: urls, fallback: fallback)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("button.close") {
                            showingWebView = false
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    Form {
        WebViewButton(
            "button.legal.imprint",
            urls: [
                .en: "https://www.apple.com",
                .de: "https://www.apple.com/de"
            ],
            fallback: .en
        )
        
        WebViewButton(
            "button.legal.privacy",
            systemImage: "lock.shield",
            urls: [
                .en: "https://www.apple.com/privacy",
                .de: "https://www.apple.com/de/privacy"
            ],
            fallback: .en
        )
    }
}
