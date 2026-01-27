//
//  InAppNotificationComponent.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

struct InAppNotificationComponent: View {
    // MARK: Parameters
    private let padding: CGFloat = 8
    private let cornerRadius: CGFloat = 32
    
    let notification: InAppNotificationObject
    @Environment(InAppNotificationService.self) private var inAppNotification
    
    // MARK: View
    var body: some View {
        HStack(spacing: .spacingL) {
            HStack(spacing: .spacingDefault) {
                if let systemImage = notification.systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                }
                
                Text(notification.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
            }
            
            Button("close.inAppNotification", systemImage: "xmark") {
                print("DEBUG: Button tapped")
                inAppNotification.currentNotification = nil
            }
            .buttonStyle(.bordered)
            .labelStyle(.iconOnly)
            .controlSize(.large)
        }
        .padding(EdgeInsets(top: padding, leading: padding * 4, bottom: padding, trailing: padding))
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.separator, lineWidth: 1)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .padding(.horizontal)
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
