//
//  InAppNotificationTestView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

public struct InAppNotificationTestView: View {
    // MARK: Init
    public init() {}
    
    // MARK: Parameters
    @Environment(InAppNotificationService.self) private var inAppNotification
    
    // MARK: View
    public var body: some View {
        VStack {
            Spacer()
            
            Button("Send Notification") {
                inAppNotification.send(InAppNotificationObject(
                    title: "Test Notification",
                    systemImage: "bell.fill"
                ))
            }
            
            Spacer()
        }
    }
}

// MARK: Preview
#Preview {
    InAppNotificationTestView()
        .setupInAppNotifications()
}
