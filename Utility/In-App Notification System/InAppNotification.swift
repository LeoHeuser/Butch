//
//  InAppNotificationComponent.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

public struct InAppNotificationComponent: View {
    // MARK: Parameters
    private let padding: CGFloat = 8
    private let cornerRadius: CGFloat = 32
    
    let notification: InAppNotificationObject
    @Environment(InAppNotificationService.self) private var inAppNotification
    
    // MARK: Init
    public init(notification: InAppNotificationObject) {
        self.notification = notification
    }
    
    // MARK: View
    public var body: some View {
        HStack(spacing: 12) {
            if let systemImage = notification.systemImage {
                Image(systemName: systemImage)
                    .font(.title2)
            }
            
            Text(notification.title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                inAppNotification.currentNotification = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.separator, lineWidth: 1)
                }
        }
    }
}

// MARK: Preview
#Preview {
    VStack {
        InAppNotificationComponent(
            notification: InAppNotificationObject(
                title: "External Microphone connected that sounds quite bad, bro",
                systemImage: "microphone.fill"
            )
        )
        
        InAppNotificationComponent(
            notification: InAppNotificationObject(
                title: "External Microphone connected that sounds quite bad, bro"
            )
        )
    }
    .environment(InAppNotificationService())
}
