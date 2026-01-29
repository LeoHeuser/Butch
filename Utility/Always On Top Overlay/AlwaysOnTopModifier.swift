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
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if isPreview {
            // Fallback für Previews: Nutze normales SwiftUI Overlay
            content
                .overlay(alignment: .top) {
                    overlayContent()
                }
        } else {
#if canImport(UIKit) || canImport(AppKit)
            // Window-basierter Modus (nur außerhalb von Previews)
            content
                .onAppear {
                    AlwaysOnTopWindowManager.shared.registerContent(overlayContent)
                }
                .onDisappear {
                    AlwaysOnTopWindowManager.shared.unregisterContent()
                }
#else
            content
                .overlay(alignment: .top) {
                    overlayContent()
                }
#endif
        }
    }
    
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

// MARK: - Window Manager

@MainActor
private class AlwaysOnTopWindowManager {
    static let shared = AlwaysOnTopWindowManager()
    
#if canImport(UIKit) || canImport(AppKit)
    private var overlayWindow: AlwaysOnTopWindow?
    private var hostingController: AlwaysOnTopHostingController?
#endif
    
    private init() {}
    
    func registerContent<Content: View>(_ content: @escaping () -> Content) {
#if canImport(UIKit) || canImport(AppKit)
        ensureWindowExists()
        
        // Wrapper View die Visibility managed
        let wrappedContent = ContentWrapper(content: content) { hasContent in
            self.updateWindowVisibility(hasContent: hasContent)
        }
        
        hostingController?.rootView = AnyView(wrappedContent)
#endif
    }
    
    func unregisterContent() {
#if canImport(UIKit) || canImport(AppKit)
        hostingController?.rootView = AnyView(Color.clear)
        updateWindowVisibility(hasContent: false)
#endif
    }
    
    private func updateWindowVisibility(hasContent: Bool) {
#if canImport(UIKit)
        overlayWindow?.isUserInteractionEnabled = hasContent
        // Window bleibt sichtbar aber nicht interaktiv wenn leer
#elseif canImport(AppKit)
        overlayWindow?.ignoresMouseEvents = !hasContent
#endif
    }
    
    private func ensureWindowExists() {
#if canImport(UIKit) || canImport(AppKit)
        guard overlayWindow == nil else { return }
        
#if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
        else {
            return
        }
        
        let window = AlwaysOnTopWindow(windowScene: scene)
#elseif canImport(AppKit)
        let window = AlwaysOnTopWindow()
#endif
        
        overlayWindow = window
        let controller = AlwaysOnTopHostingController(rootView: AnyView(Color.clear))
        hostingController = controller
        
#if canImport(UIKit)
        window.rootViewController = controller
        window.isHidden = false
        window.isUserInteractionEnabled = false // Initial aus
#elseif canImport(AppKit)
        window.contentViewController = controller
        window.orderFront(nil)
        window.ignoresMouseEvents = true // Initial aus
#endif
#endif
    }
}

// MARK: - Content Wrapper

private struct ContentWrapper<Content: View>: View {
    let content: () -> Content
    let onVisibilityChange: (Bool) -> Void
    
    @State private var hasVisibleContent = false
    
    var body: some View {
        content()
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            checkVisibility(size: geometry.size)
                        }
                        .onChange(of: geometry.size) { oldValue, newValue in
                            checkVisibility(size: newValue)
                        }
                }
            )
    }
    
    private func checkVisibility(size: CGSize) {
        let isVisible = size.width > 0 && size.height > 0
        if isVisible != hasVisibleContent {
            hasVisibleContent = isVisible
            onVisibilityChange(isVisible)
        }
    }
}

// MARK: - UIKit Window (iOS)

#if canImport(UIKit)
@MainActor
private final class AlwaysOnTopWindow: UIWindow {
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        
        self.windowLevel = .alert + 1
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
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
        
        // Wenn wir die contentView selbst getroffen haben (transparenter Background), durchreichen
        if hitView == self.contentView {
            return nil
        }
        
        // Prüfe ob wir einen transparenten SwiftUI View getroffen haben
        if let view = hitView, isTransparentView(view) {
            return nil
        }
        
        return hitView
    }
    
    private func isTransparentView(_ view: NSView) -> Bool {
        // Prüfe ob die View transparent ist und keine interaktiven Subviews hat
        if view.layer?.backgroundColor != nil && view.layer?.backgroundColor != NSColor.clear.cgColor {
            return false
        }
        
        // Wenn die View GestureRecognizers hat, ist sie interaktiv
        if !view.gestureRecognizers.isEmpty {
            return false
        }
        
        // Prüfe ob irgendwelche Subviews interaktiv sind
        for subview in view.subviews {
            if !isTransparentView(subview) {
                return false
            }
        }
        
        return true
    }
}
#endif

// MARK: - Hosting Controller

#if canImport(UIKit)
@MainActor
private final class AlwaysOnTopHostingController: UIHostingController<AnyView> {
    
    override init(rootView: AnyView) {
        super.init(rootView: rootView)
        
        let passThroughView = PassThroughView()
        passThroughView.translatesAutoresizingMaskIntoConstraints = false
        passThroughView.backgroundColor = .clear
        
        // Wrap the hosting view
        let originalView = view!
        view = passThroughView
        
        passThroughView.addSubview(originalView)
        originalView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            originalView.topAnchor.constraint(equalTo: passThroughView.topAnchor),
            originalView.bottomAnchor.constraint(equalTo: passThroughView.bottomAnchor),
            originalView.leadingAnchor.constraint(equalTo: passThroughView.leadingAnchor),
            originalView.trailingAnchor.constraint(equalTo: passThroughView.trailingAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}

private class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        // Wenn wir uns selbst oder die Hosting-View getroffen haben (transparenter Background),
        // dann Touch durchreichen
        if hitView == self || hitView?.backgroundColor == .clear && hitView?.subviews.isEmpty == true {
            return nil
        }
        
        // Wenn der Hit nur auf einem SwiftUI Background View ist, durchreichen
        // SwiftUI Views die nur .clear sind sollten nicht Touches abfangen
        if let hostingView = hitView, isTransparentSwiftUIView(hostingView) {
            return nil
        }
        
        // Ansonsten haben wir tatsächlichen Content getroffen
        return hitView
    }
    
    private func isTransparentSwiftUIView(_ view: UIView) -> Bool {
        // Prüfe ob die View transparent ist und keine interaktiven Subviews hat
        guard view.backgroundColor == .clear || view.backgroundColor == nil else {
            return false
        }
        
        // Wenn die View einen GestureRecognizer hat, ist sie interaktiv
        if let gestureRecognizers = view.gestureRecognizers, !gestureRecognizers.isEmpty {
            return false
        }
        
        // Prüfe ob irgendwelche Subviews interaktiv sind
        for subview in view.subviews {
            if !isTransparentSwiftUIView(subview) {
                return false
            }
        }
        
        return true
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
