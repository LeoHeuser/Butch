//
//  InAppNotificationTestView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

public struct InAppNotificationTestView: View {
    @Environment(InAppNotificationService.self) private var inAppNotification
    
    public var body: some View {
        VStack {
            Spacer()
            Button("Send Notification") {
                inAppNotification.send(InAppNotificationObject(
                    title: "Test Notification",
                    message: "This is a test message",
                    systemImage: "bell.fill"
                ))
            }
            Spacer()
        }
    }
}


#Preview {
    InAppNotificationTestView()
        .setupInAppNotifications()
}
