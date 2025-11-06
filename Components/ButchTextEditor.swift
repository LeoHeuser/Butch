//
//  ButchTextEditor.swift
//  ButchSDK
//
//  Created by Leo Heuser on 06.11.25.
//

import SwiftUI

public struct ButchTextEditor: View {
    // MARK: - Parameters
    @Binding private var text: String
    private let placeholder: LocalizedStringKey
    
    // MARK: - Initializer
    public init(text: Binding<String>, placeholder: LocalizedStringKey = "placeholder.text") {
        self._text = text
        self.placeholder = placeholder
    }
    
    // MARK: - View
    public var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 16))
            .foregroundStyle(text.isEmpty ? Color.primary.opacity(0.4) : Color.primary.opacity(0.9))
            .frame(minHeight: 108)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.primary.opacity(0.4))
                        .padding(16)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - Preview
#Preview {
    ButchTextEditor(text: .constant(""))
        .padding()
}
