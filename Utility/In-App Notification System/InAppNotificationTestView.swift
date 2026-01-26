//
//  InAppNotificationTestView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

public struct InAppNotificationTestView: View {
    @State var notificationService = InAppNotificationService()
    
    public init() {}
    
    public var body: some View {
        VStack {
            Spacer()
            Button("Send Notification") {
                notificationService.send(InAppNotificationObject(
                    title: "Test Notification",
                    message: "This is a test message",
                    systemImage: "bell.fill"
                ))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inAppNotificationOverlay(service: notificationService)
    }
}

#Preview {
    InAppNotificationTestView()
}
