//
//  File.swift
//  ButchSDK
//
//  Created by Leo Heuser on 09.10.25.
//

import Foundation
import SwiftUI

/// Defines the visual style variant for ButchButtonStyle
public enum ButchButtonKind {
    case primary
    case secondary
}

/// A custom button style matching the Butch design system
public struct ButchButtonStyle: ButtonStyle {
    private let kind: ButchButtonKind
    
    public init(_ kind: ButchButtonKind = .primary) {
        self.kind = kind
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(kind == .primary ? Color(white: 1, opacity: 0.9) : Color(white: 0, opacity: 0.9))
            .background(backgroundForKind(configuration.isPressed))
            .clipShape(Capsule())
    }
    
    @ViewBuilder
    private func backgroundForKind(_ isPressed: Bool) -> some View {
        Group {
            switch kind {
            case .primary:
                Color.black
                    .opacity(isPressed ? 0.7 : 1)
            case .secondary:
                Color.white
                    .opacity(isPressed ? 0.7 : 1)
                    .overlay(Capsule().stroke(Color.black.opacity(0.2), lineWidth: 1))
            }
        }
    }
}

public extension ButtonStyle where Self == ButchButtonStyle {
    static var butch: ButchButtonStyle { ButchButtonStyle() }
    static func butch(_ kind: ButchButtonKind) -> ButchButtonStyle { ButchButtonStyle(kind) }
}

#Preview {
    VStack {
        Button("Primary Button", systemImage: "gear") {}
            .buttonStyle(.butch)
        
        Button("Secondary Button", systemImage: "gear") {}
            .buttonStyle(.butch(.secondary))
        
        Button("Text Only") {}
            .buttonStyle(.butch)
    }
    .padding()
}
