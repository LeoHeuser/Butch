//
//  ButchContentPlaceholder.swift
//  Butch
//
//  Created by Leo Heuser on 08.10.25.
//

import SwiftUI

public struct ButchContentPlaceholder: View {
    // MARK: - Parameters
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    
    // MARK: - Initializer
    public init(title: LocalizedStringKey, message: LocalizedStringKey? = nil) {
        self.title = title
        self.message = message
    }
    
    // MARK: - View
    public var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text(title)
                .font(.title)
                .fontWeight(.heavy)
                .lineLimit(1)
            
            if let message {
                Text(message)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(4)
            }
        }
        .foregroundStyle(Color.textSecondary)
        .multilineTextAlignment(.leading)
    }
}

// MARK: - Preview
#Preview {
    Spacer()
    
    ButchContentPlaceholder(
        title: "placeholder.title",
        message: "placeholder.message"
    )
    
    Spacer()
    
    ButchContentPlaceholder(
        title: "placeholder.title"
    )
    
    Spacer()
}
