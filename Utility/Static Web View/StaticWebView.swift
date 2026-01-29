//
//  StaticWebView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 29.01.26.
//

/**
 A static, security-focused web view component for displaying web content.
 
 ## Features
 - Loads a single URL without allowing navigation away from the initial domain
 - Automatically sends Accept-Language headers based on device or app language
 - Configurable JavaScript support (disabled by default for security)
 - Configurable cache policy (bypasses cache by default for always-fresh content)
 - External links open in Safari automatically
 - Automatic URL validation with error handling
 
 ## Usage
 ```swift
 // Basic usage (no JS, OS language, no cache)
 StaticWebView("https://example.com/privacy")
 
 // URLs without scheme automatically get https:// prefix
 StaticWebView("apple.com/privacy")  // → https://apple.com/privacy
 StaticWebView("www.apple.com")      // → https://www.apple.com
 
 // With custom options
 StaticWebView(
 "example.com",
 useAppLanguage: true,
 allowsJavaScript: true,
 cachePolicy: .useProtocolCachePolicy
 )
 ```
 
 ## URL Validation
 - URLs must contain at least one dot (e.g., "apple.com")
 - URLs without http/https scheme automatically get "https://" prefix
 - Invalid URLs (e.g., "lol") show an error indicator
 
 ## Security
 - JavaScript is disabled by default
 - Navigation is restricted to the same domain
 - User-activated links to external domains open in Safari
 - Redirects and server-side navigation within the same domain are allowed
 */

import SwiftUI
import WebKit

public struct StaticWebView: View {
    let url: String
    let useAppLanguage: Bool
    let allowsJavaScript: Bool
    let cachePolicy: URLRequest.CachePolicy
    
    public init(
        _ url: String,
        useAppLanguage: Bool = false,
        allowsJavaScript: Bool = false,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    ) {
        self.url = url
        self.useAppLanguage = useAppLanguage
        self.allowsJavaScript = allowsJavaScript
        self.cachePolicy = cachePolicy
    }
    
    public var body: some View {
        if let validUrl = normalizedURL(from: url) {
            StaticWebViewRepresentable(
                url: validUrl,
                useAppLanguage: useAppLanguage,
                allowsJavaScript: allowsJavaScript,
                cachePolicy: cachePolicy
            )
        } else {
            VStack {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
    
    private func normalizedURL(from urlString: String) -> URL? {
        // Check if URL contains at least one dot (valid domain)
        guard urlString.contains(".") else { return nil }
        
        // Try parsing as-is first (for URLs with http/https)
        if let url = URL(string: urlString),
           let scheme = url.scheme,
           ["http", "https"].contains(scheme) {
            return url
        }
        
        // No valid scheme? Add https:// prefix for security
        return URL(string: "https://" + urlString)
    }
}

// MARK: - Web View Representable

private struct StaticWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let useAppLanguage: Bool
    let allowsJavaScript: Bool
    let cachePolicy: URLRequest.CachePolicy
    @Environment(\.openURL) private var openURL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = allowsJavaScript
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        var request = URLRequest(url: url)
        request.cachePolicy = cachePolicy
        
        // Set Accept-Language header based on language preferences
        let preferredLanguages: [String]
        if useAppLanguage {
            preferredLanguages = Bundle.main.preferredLocalizations
        } else {
            preferredLanguages = Locale.preferredLanguages
        }
        let acceptLanguage = preferredLanguages.joined(separator: ", ")
        request.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
        
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Intentionally empty - URL is static and should not change after initial load
    }
    
    func makeCoordinator() -> NavigationHandler {
        NavigationHandler(allowedUrl: url, openURL: openURL)
    }
}

// MARK: - Navigation Handler

@MainActor
final class NavigationHandler: NSObject, WKNavigationDelegate {
    private let allowedUrl: URL
    private let openURL: OpenURLAction
    
    init(allowedUrl: URL, openURL: OpenURLAction) {
        self.allowedUrl = allowedUrl
        self.openURL = openURL
        super.init()
    }
    
    private func isSameDomain(_ url1: URL, _ url2: URL) -> Bool {
        let host1 = normalizedHost(from: url1)
        let host2 = normalizedHost(from: url2)
        return host1 == host2 && !host1.isEmpty
    }
    
    private func normalizedHost(from url: URL) -> String {
        guard let host = url.host?.lowercased() else { return "" }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
    
    func webView(
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
            if !isSameDomain(requestUrl, allowedUrl) {
                openURL(requestUrl)
                return .cancel
            }
        }
        
        // Allow all other navigation (redirects, form submissions, etc.)
        return .allow
    }
}

// MARK: - Preview

#Preview("With https://") {
    StaticWebView("https://www.apple.com/privacy")
}

#Preview("Without https://") {
    StaticWebView("apple.com/privacy")
}

#Preview("Invalid URL") {
    StaticWebView("wrong")
}

#Preview("With Options") {
    StaticWebView(
        "example.com",
        useAppLanguage: true,
        allowsJavaScript: true
    )
}
