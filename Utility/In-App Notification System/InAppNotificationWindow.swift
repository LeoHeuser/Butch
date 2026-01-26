//
//  InAppNotificationWindow.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

#if canImport(UIKit)
import UIKit
import SwiftUI

@MainActor
final class InAppNotificationWindow: UIWindow {

    init() {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene

        super.init(windowScene: scene!)

        self.windowLevel = .alert + 1
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView == self.rootViewController?.view {
            return nil
        }

        return hitView
    }
}
#endif

#if canImport(AppKit)
import AppKit
import SwiftUI

@MainActor
final class InAppNotificationWindow: NSPanel {

    init() {
        super.init(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hitView = super.hitTest(point)

        if hitView == self.contentView {
            return nil
        }

        return hitView
    }
}
#endif
