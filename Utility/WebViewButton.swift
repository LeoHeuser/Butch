//
//  WebViewButton.swift
//  Butch
//
//  Created by Leo Heuser on 26.05.25.
//

import SwiftUI
import WebKit

public struct WebViewButton: View {
    // MARK: - Properties
    let title: LocalizedStringKey
    let systemImage: String?
    let toUrl: URL
    
    @State private var showingWebView = false
    
    // MARK: - Initializer
    public init(_ title: LocalizedStringKey, systemImage: String? = nil, toUrl: URL) {
        self.title = title
        self.systemImage = systemImage
        self.toUrl = toUrl
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
            WebViewSheet(title: title, url: toUrl, isPresented: $showingWebView)
        }
    }
}

// MARK: - WebView Sheet

private struct WebViewSheet: View {
    let title: LocalizedStringKey
    let url: URL
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            StaticWebView(url: url)
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

// MARK: - Static WebView

private struct StaticWebView: UIViewRepresentable {
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
    Form {
        WebViewButton(
            "button.legal.imprint",
            toUrl: URL(string: "https://www.apple.com")!
        )
        
        WebViewButton(
            "button.legal.privacy",
            systemImage: "lock.shield",
            toUrl: URL(string: "https://www.apple.com")!
        )
    }
}
