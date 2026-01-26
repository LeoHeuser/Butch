//
//  InAppNotificationService.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public struct InAppNotificationObject {
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey?
    public let systemImage: String?

    public init(title: LocalizedStringKey, message: LocalizedStringKey? = nil, systemImage: String? = nil) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }
}

@Observable
@MainActor
public class InAppNotificationService {
    public var currentNotification: InAppNotificationObject? {
        didSet {
            updateWindow()
        }
    }

    #if canImport(UIKit) || canImport(AppKit)
    private var notificationWindow: InAppNotificationWindow?
    private var windowHost: InAppNotificationWindowHost?
    #endif

    public init() {}

    public func send(_ notification: InAppNotificationObject) {
        currentNotification = notification

        Task {
            try? await Task.sleep(for: .seconds(3))
            if currentNotification?.title == notification.title {
                currentNotification = nil
            }
        }
    }

    #if canImport(UIKit) || canImport(AppKit)
    private func updateWindow() {
        if notificationWindow == nil {
            notificationWindow = InAppNotificationWindow()
            windowHost = InAppNotificationWindowHost()

            #if canImport(UIKit)
            notificationWindow?.rootViewController = windowHost
            #elseif canImport(AppKit)
            notificationWindow?.contentViewController = windowHost
            #endif
        }

        withAnimation(.spring) {
            windowHost?.updateNotification(currentNotification, service: self)
        }

        #if canImport(UIKit)
        notificationWindow?.isHidden = currentNotification == nil
        #elseif canImport(AppKit)
        if currentNotification == nil {
            notificationWindow?.orderOut(nil)
        } else {
            notificationWindow?.orderFront(nil)
        }
        #endif
    }
    #endif
}
