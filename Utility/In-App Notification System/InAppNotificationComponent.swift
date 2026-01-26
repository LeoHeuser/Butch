//
//  InAppNotificationComponent.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

struct InAppNotificationComponent: View {
    let notification: InAppNotificationObject
    let service: InAppNotificationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            RoundedRectangle(cornerRadius: 16)
                .stroke(.separator)
                .fill(.thinMaterial)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .onTapGesture {
            service.currentNotification = nil
        }
    }
}

public extension View {
    func inAppNotificationOverlay(service: InAppNotificationService) -> some View {
        modifier(InAppNotificationOverlayModifier(service: service))
    }
}

struct InAppNotificationOverlayModifier: ViewModifier {
    let service: InAppNotificationService
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if let notification = service.currentNotification {
                    VStack {
                        InAppNotificationComponent(notification: notification, service: service)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring, value: service.currentNotification != nil)
    }
}

#Preview {
    @Previewable @State var service = InAppNotificationService()
    
    VStack {
        Spacer()
        Button("Show Notification") {
            service.send(InAppNotificationObject(
                title: "notification.title",
                message: "notification.message",
                systemImage: "circle.square"
            ))
        }
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
    .inAppNotificationOverlay(service: service)
}
