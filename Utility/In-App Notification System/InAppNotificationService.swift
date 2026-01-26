//
//  InAppNotificationService.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import SwiftUI

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
    public var currentNotification: InAppNotificationObject?

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
}
