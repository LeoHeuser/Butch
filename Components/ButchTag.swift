//
//  ButchTag.swift
//  Butch
//
//  Created by Leo Heuser on 26.09.25.
//

import SwiftUI

public struct ButchTag: View {
    // MARK: - Parameters
    private let title: LocalizedStringKey
    
    // MARK: - Initializer
    public init(_ title: LocalizedStringKey) {
        self.title = title
    }
    
    // MARK: - Component
    public var body: some View {
        TagContent(title: title)
            .padding(.horizontal, .spacing16)
            .padding(.vertical, .spacing8)
            .background(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: .infinity)
                    .strokeBorder(Color.gray080, lineWidth: 1)
            )
    }
}

// MARK: - Component Parts
extension ButchTag {
    
    /// Tag Content
    private struct TagContent: View {
        let title: LocalizedStringKey
        
        var body: some View {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Example of Use and Preview
#Preview("ButchTag") {
    VStack(spacing: .spacing16) {
        ButchTag("tag.category")
        ButchTag("tag.featured")
        ButchTag("tag.new")
        ButchTag("tag.premium")
    }
    .padding()
}
