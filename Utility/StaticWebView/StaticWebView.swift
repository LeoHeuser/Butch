//
//  StaticWebView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 29.01.26.
//

import SwiftUI
import WebKit

public struct StaticWebView: View {
    // MARK: - Properties
    let title: LocalizedStringKey
    let urls: [Locale.LanguageCode: String]
    let fallback: Locale.LanguageCode

    /// Resolves the URL based on the current app language.
    private var resolvedUrl: String {
        let currentLanguage = Locale.current.language.languageCode ?? fallback
        return urls[currentLanguage] ?? urls[fallback] ?? ""
    }

    // MARK: - Initializer
    public init(
        _ title: LocalizedStringKey,
        urls: [Locale.LanguageCode: String],
        fallback: Locale.LanguageCode
    ) {
        self.title = title
        self.urls = urls
        self.fallback = fallback
    }

    // MARK: - View
    public var body: some View {
        NavigationStack {
            Group {
                if let url = URL(string: resolvedUrl) {
                    InternalWebView(url: url)
                } else {
                    InvalidURLView()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Internal WebView

private struct InternalWebView: UIViewRepresentable {
    let url: URL
    @Environment(\.openURL) private var openURL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> NavigationHandler {
        NavigationHandler(allowedUrl: url, openURL: openURL)
    }
}

// MARK: - Navigation Handler

@MainActor
private final class NavigationHandler: NSObject, WKNavigationDelegate {
    let allowedUrl: URL
    let openURL: OpenURLAction

    init(allowedUrl: URL, openURL: OpenURLAction) {
        self.allowedUrl = allowedUrl
        self.openURL = openURL
        super.init()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let requestUrl = navigationAction.request.url else { return .cancel }

        let isAllowed = requestUrl.host == allowedUrl.host && requestUrl.path == allowedUrl.path

        if isAllowed {
            return .allow
        } else {
            openURL(requestUrl)
            return .cancel
        }
    }
}

// MARK: - Preview

#Preview {
    StaticWebView(
        "Privacy Policy",
        urls: [
            .en: "https://www.apple.com/privacy",
            .de: "https://www.apple.com/de/privacy"
        ],
        fallback: .en
    )
}
