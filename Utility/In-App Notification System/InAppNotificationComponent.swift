//
//  InAppNotificationComponent.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

struct InAppNotificationComponent: View {
    var image: String
    var title: LocalizedStringKey
    var message: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: image)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            Text(message)
                .font(.body)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 32)
                .stroke(.separator)
                .fill(.thinMaterial)
        }
    }
}

#Preview {
    InAppNotificationComponent(image: "circle.square", title: "notification.title", message: "notification.message")
}
