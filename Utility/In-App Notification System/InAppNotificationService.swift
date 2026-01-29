//
//  InAppNotificationService.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

// MARK: Struct Element
public struct InAppNotificationObject {
    public let title: LocalizedStringKey
    public let systemImage: String?
    
    public init(title: LocalizedStringKey, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }
}

// MARK: In-App Notification Service definition
@Observable
@MainActor
public class InAppNotificationService {
    public var currentNotification: InAppNotificationObject?
    
    // TODO: Hier prüfen ob das init raus kann. Das macht ja nichts und dann ist es unnötig.
    public init() {}
    
    public func send(_ notification: InAppNotificationObject) {
        currentNotification = notification
        
        Task {
            try? await Task.sleep(for: .seconds(10))
            if currentNotification?.title == notification.title {
                currentNotification = nil
            }
        }
    }
}

// MARK: View initialization elements
public extension View {
    func setupInAppNotifications() -> some View {
        modifier(InAppNotificationOverlayModifier())
    }
}

private struct InAppNotificationOverlayContent: View {
    @Environment(InAppNotificationService.self) private var service
    
    var body: some View {
        VStack(spacing: 0) {
            if let notification = service.currentNotification {
                InAppNotificationComponent(notification: notification)
                    .padding(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(service.currentNotification != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: service.currentNotification != nil)
    }
}

private struct InAppNotificationOverlayModifier: ViewModifier {
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
