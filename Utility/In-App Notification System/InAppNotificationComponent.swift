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
        if notification.message == nil {
            titleOnlyLayout
        } else {
            titleWithMessageLayout
        }
    }
    
    private var titleOnlyLayout: some View {
        HStack(spacing: .spacingS) {
            if let systemImage = notification.systemImage {
                Image(systemName: systemImage)
                    .font(.title2)
            }

            Text(notification.title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("close.inAppNotification", systemImage: "xmark") {
                print("DEBUG: Button tapped")
                inAppNotification.currentNotification = nil
            }
            .buttonStyle(.bordered)
            .labelStyle(.iconOnly)
        }
        .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 16))
        .background {
            RoundedRectangle(cornerRadius: 32)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(.separator, lineWidth: 1)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 32))
        .padding(.horizontal)
    }
    
    private var titleWithMessageLayout: some View {
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
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(.separator, lineWidth: 1)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 32))
        .padding(.horizontal)
        .onTapGesture {
            print("DEBUG: Notification tapped")
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
            .alwaysOnTopOverlay {
                InAppNotificationOverlayContent()
                    .environment(inAppNotification)
            }
    }
}

struct InAppNotificationOverlayContent: View {
    @Environment(InAppNotificationService.self) private var service

    var body: some View {
        VStack(spacing: 0) {
            if let notification = service.currentNotification {
                InAppNotificationComponent(notification: notification)
                    .padding(.top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer(minLength: 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Leerer Bereich - nichts tun
                }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: service.currentNotification != nil)
    }
}

#Preview {
    VStack {
        InAppNotificationComponent(
            notification: InAppNotificationObject(
                title: "Test Notification",
                message: "This is a preview message",
                systemImage: "bell.fill"
            )
        )
        
        InAppNotificationComponent(
            notification: InAppNotificationObject(
                title: "Test Notification")
        )
    }
    .environment(InAppNotificationService())
}
