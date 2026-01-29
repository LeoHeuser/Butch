//
//  SwiftWebView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 27.01.26.
//

import SwiftUI

// TODO: Die Webview kann irgendwann dann mal raus.

public struct SwiftWebView: View {
    public let title: LocalizedStringKey
    public let urlString: String
    
    public init(_ title: LocalizedStringKey, url: String) {
        self.title = title
        self.urlString = url
    }
    
    public var body: some View {
        StaticWebView(
            title,
            urls: [.en: urlString],
            fallback: .en
        )
    }
}

// MARK: - Preview

#Preview {
    SwiftWebView("Apple Website", url: "https://www.apple.com")
}
