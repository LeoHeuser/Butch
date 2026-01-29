//
//  StaticWebView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 29.01.26.
//

import SwiftUI
import WebKit

public struct StaticWebView: UIViewRepresentable {
    public let url: URL
    @Environment(\.openURL) private var openURL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
        
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {}
    
    public func makeCoordinator() -> NavigationHandler {
        NavigationHandler(allowedUrl: url, openURL: openURL)
    }
}

// MARK: - Navigation Handler

@MainActor
public final class NavigationHandler: NSObject, WKNavigationDelegate {
    let allowedUrl: URL
    let openURL: OpenURLAction
    
    public init(allowedUrl: URL, openURL: OpenURLAction) {
        self.allowedUrl = allowedUrl
        self.openURL = openURL
        super.init()
    }
    
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let requestUrl = navigationAction.request.url else { return .cancel }
        
        // Allow initial load
        if webView.url == nil {
            return .allow
        }
        
        // Open user-activated links (clicks) in Safari if they navigate away
        if navigationAction.navigationType == .linkActivated {
            let isSameHost = requestUrl.host == allowedUrl.host
            
            if !isSameHost {
                openURL(requestUrl)
                return .cancel
            }
        }
        
        // Allow all other navigation (redirects, form submissions, etc.)
        return .allow
    }
}

// MARK: - Preview

#Preview {
    StaticWebView(url: URL(string: "https://www.apple.com/privacy")!)
}
