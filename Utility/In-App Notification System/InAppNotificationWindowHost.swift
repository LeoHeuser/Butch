//
//  InAppNotificationWindowHost.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

@MainActor
final class InAppNotificationWindowHost: UIHostingController<AnyView> {

    init() {
        super.init(rootView: AnyView(Color.clear))
        view.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func updateNotification(_ notification: InAppNotificationObject?, service: InAppNotificationService) {
        if let notification = notification {
            let notificationView = InAppNotificationComponent(notification: notification)
                .environment(service)

            let containerView = VStack {
                notificationView
                    .padding(.top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Spacer()
            }

            rootView = AnyView(containerView)
        } else {
            rootView = AnyView(Color.clear)
        }
    }
}
#endif

#if canImport(AppKit)
import SwiftUI
import AppKit

@MainActor
final class InAppNotificationWindowHost: NSHostingController<AnyView> {

    init() {
        super.init(rootView: AnyView(Color.clear))
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func updateNotification(_ notification: InAppNotificationObject?, service: InAppNotificationService) {
        if let notification = notification {
            let notificationView = InAppNotificationComponent(notification: notification)
                .environment(service)

            let containerView = VStack {
                notificationView
                    .padding(.top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Spacer()
            }

            rootView = AnyView(containerView)
        } else {
            rootView = AnyView(Color.clear)
        }
    }
}
#endif
