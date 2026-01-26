//
//  InAppNotificationComponent.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

struct InAppNotificationComponent: View {
    let notification: InAppNotificationObject
    @Environment(InAppNotificationService.self) private var inAppNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                if let systemImage = notification.systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                }
                Text(notification.title)
                    .font(.headline)
            }
            if let message = notification.message {
                Text(message)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 32)
                .stroke(.separator)
                .fill(.thinMaterial)
        }
        .padding(.horizontal)
        .onTapGesture {
            inAppNotification.currentNotification = nil
        }
    }
}

public extension View {
    func setupInAppNotifications() -> some View {
        modifier(InAppNotificationOverlayModifier())
    }
}

struct InAppNotificationOverlayModifier: ViewModifier {
    @State private var inAppNotification = InAppNotificationService()

    func body(content: Content) -> some View {
        content
            .environment(inAppNotification)
    }
}

#Preview {
    InAppNotificationComponent(
        notification: InAppNotificationObject(
            title: "Test Notification",
            message: "This is a preview message",
            systemImage: "bell.fill"
        )
    )
    .environment(InAppNotificationService())
}
