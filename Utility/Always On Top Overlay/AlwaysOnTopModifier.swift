//
//  AlwaysOnTopModifier.swift
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

// MARK: - Public API

public extension View {
    func alwaysOnTopOverlay<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(AlwaysOnTopOverlayModifier(overlayContent: content))
    }
}

// MARK: - Modifier

struct AlwaysOnTopOverlayModifier<OverlayContent: View>: ViewModifier {
    let overlayContent: () -> OverlayContent

    func body(content: Content) -> some View {
        content
            .onAppear {
                AlwaysOnTopWindowManager.shared.setupWindow(content: overlayContent)
            }
    }
}

// MARK: - Window Manager

@MainActor
private class AlwaysOnTopWindowManager {
    static let shared = AlwaysOnTopWindowManager()

    #if canImport(UIKit) || canImport(AppKit)
    private var overlayWindow: AlwaysOnTopWindow?
    #endif

    private init() {}

    func setupWindow<Content: View>(content: @escaping () -> Content) {
        #if canImport(UIKit) || canImport(AppKit)
        guard overlayWindow == nil else { return }

        overlayWindow = AlwaysOnTopWindow()
        let hostingController = AlwaysOnTopHostingController(rootView: AnyView(content()))

        #if canImport(UIKit)
        overlayWindow?.rootViewController = hostingController
        overlayWindow?.isHidden = false
        #elseif canImport(AppKit)
        overlayWindow?.contentViewController = hostingController
        overlayWindow?.orderFront(nil)
        #endif
        #endif
    }
}

// MARK: - UIKit Window (iOS)

#if canImport(UIKit)
@MainActor
private final class AlwaysOnTopWindow: UIWindow {

    init() {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene

        super.init(windowScene: scene!)

        self.windowLevel = .alert + 1
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
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

// MARK: - AppKit Window (macOS)

#if canImport(AppKit)
@MainActor
private final class AlwaysOnTopWindow: NSPanel {

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

// MARK: - Hosting Controller

#if canImport(UIKit)
@MainActor
private final class AlwaysOnTopHostingController: UIHostingController<AnyView> {

    override init(rootView: AnyView) {
        super.init(rootView: rootView)
        view.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
#endif

#if canImport(AppKit)
@MainActor
private final class AlwaysOnTopHostingController: NSHostingController<AnyView> {

    override init(rootView: AnyView) {
        super.init(rootView: rootView)
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
#endif
