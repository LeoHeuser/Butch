//
//  SwiftWebView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 27.01.26.
//

import SwiftUI
import WebKit

public struct SwiftWebView: View {
    var urlString: String
    var title: LocalizedStringKey
    
    public init(_ urlString: String, title: LocalizedStringKey) {
        self.urlString = urlString
        self.title = title
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if let url = URL(string: urlString) {
                    if #available(iOS 26.0, *) {
                        WebView(url: url)
                            .onOpenURL { url in
                                UIApplication.shared.open(url)
                            }
                    } else {
                        OldWebView(url: url)
                    }
                } else {
                    // TODO: Hier nochmal eine richtige URL-Validierung einbauen. Wenn ich einen leeren String eingebe mit "" dann kommt der Fehler aber sobal dich nur schon "hallo" eingebe, dann kommt der Fehler nicht mehr. Das kann man noch verbessern an der Stelle.
                    ContentUnavailableView(
                        "Invalid URL",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The provided URL '\(urlString)' is not valid.")
                    )
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@available(iOS 17.0, *)
public struct OldWebView: UIViewRepresentable {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        let initialURL: URL
        
        init(url: URL) {
            self.initialURL = url
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
            guard let url = navigationAction.request.url else {
                return (.cancel, preferences)
            }
            
            // Allow initial load
            if url == initialURL && webView.url == nil {
                return (.allow, preferences)
            }
            
            // Open all other links in Safari
            if navigationAction.navigationType == .linkActivated {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
                return (.cancel, preferences)
            }
            
            return (.allow, preferences)
        }
    }
}

#Preview {
    SwiftWebView("www.apple.com", title: "Apple Website")
}
