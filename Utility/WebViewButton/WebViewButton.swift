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
            WebViewSheet(
                title: title,
                urls: urls,
                fallback: fallback,
                isPresented: $showingWebView
            )
        }
    }
}

// MARK: - WebView Sheet

private struct WebViewSheet: View {
    let title: LocalizedStringKey
    let urls: [Locale.LanguageCode: String]
    let fallback: Locale.LanguageCode
    @Binding var isPresented: Bool
    
    private var resolvedUrl: String {
        let currentLanguage = Locale.current.language.languageCode ?? fallback
        return urls[currentLanguage] ?? urls[fallback] ?? ""
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let url = URL(string: resolvedUrl) {
                    StaticWebView(url: url)
                } else {
                    InvalidURLView()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Invalid URL View

private struct InvalidURLView: View {
    var body: some View {
        ContentUnavailableView(
            "error.invalidUrl",
            systemImage: "exclamationmark.bubble"
        )
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
