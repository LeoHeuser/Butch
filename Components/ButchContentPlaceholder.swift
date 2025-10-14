//
//  File.swift
//  Butch
//
//  Created by Leo Heuser on 08.10.25.
//

import SwiftUI

struct ButchContentPlaceholder: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 32, weight: .heavy))
                .lineLimit(1)
            
            Text(message)
                .font(.system(size: 20, weight: .medium))
                .lineLimit(4)
        }
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    ButchContentPlaceholder(
        title: "placeholder.title",
        message: "placeholder.message"
    )
}
