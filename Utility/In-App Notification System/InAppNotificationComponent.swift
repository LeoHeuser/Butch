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
            .alwaysOnTopOverlay {
                InAppNotificationOverlayContent()
                    .environment(inAppNotification)
            }
    }
}

struct InAppNotificationOverlayContent: View {
    @Environment(InAppNotificationService.self) private var service
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                if let notification = service.currentNotification {
                    InAppNotificationComponent(notification: notification)
                        .padding(.top)
                        .offset(y: dragOffset)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($dragOffset) { value, state, _ in
                                    let translation = value.translation.height
                                    state = min(0, translation)
                                }
                                .onChanged { _ in
                                    isDragging = true
                                }
                                .onEnded { value in
                                    isDragging = false
                                    let translation = value.translation.height
                                    let velocity = value.predictedEndTranslation.height - translation

                                    let shouldDismiss = translation < -80 || velocity < -200

                                    if shouldDismiss {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            service.currentNotification = nil
                                        }
                                    }
                                }
                        )
                }
                Spacer()
            }
            .animation(isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.75), value: service.currentNotification != nil)
        }
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
