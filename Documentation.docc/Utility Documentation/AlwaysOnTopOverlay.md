# Always On Top Overlay

Ein wiederverwendbarer SwiftUI Modifier, der Inhalte über allen anderen UI-Elementen anzeigt, einschließlich Sheets und Alerts.

## Übersicht

Der `alwaysOnTopOverlay` Modifier nutzt eine minimale UIKit/AppKit Bridge, um SwiftUI Inhalte auf der obersten Window-Ebene zu rendern. Die gesamte UI-Logik, Animationen und Interaktionen bleiben in SwiftUI.

## Verwendung

```swift
import SwiftUI
import ButchSDK

struct ContentView: View {
    @State private var showOverlay = false

    var body: some View {
        VStack {
            Button("Toggle Overlay") {
                showOverlay.toggle()
            }
        }
        .alwaysOnTopOverlay {
            if showOverlay {
                MyOverlayContent()
                    .transition(.scale)
            }
        }
    }
}
```

## Technische Details

### Architektur

- **UIKit Bridge**: Minimal - nur für `windowLevel` (z-ordering)
- **SwiftUI**: Alle UI-Komponenten, Animationen, Transitions, Gestures
- **Platform Support**: iOS 17+, macOS 14+

### Window Level

- **iOS**: `UIWindow.Level.alert + 1`
- **macOS**: `NSWindow.Level.floating`

### Hit Testing

Der Modifier implementiert intelligentes Hit Testing:
- Touches außerhalb des Overlay-Contents werden an die darunterliegenden Views weitergereicht
- Nur der tatsächliche Overlay-Content ist interaktiv

## Best Practices

1. **Transparenter Background**: Nutze `Color.clear` mit `.ignoresSafeArea()` als Background
2. **Hit Testing**: Setze `.allowsHitTesting(false)` auf nicht-interaktive Bereiche
3. **Animationen**: Nutze normale SwiftUI Animationen (`.spring`, `.transition`, etc.)
4. **Gestures**: Funktionieren normal (`.gesture()`, `.onTapGesture()`, etc.)

## Beispiele

### Notification Overlay

```swift
.alwaysOnTopOverlay {
    VStack {
        if let notification = notifications.current {
            NotificationView(notification)
                .transition(.move(edge: .top))
        }
        Spacer()
    }
    .animation(.spring, value: notifications.current != nil)
}
```

### Floating Controls

```swift
.alwaysOnTopOverlay {
    VStack {
        Spacer()
        HStack {
            Spacer()
            FloatingActionButton()
                .padding()
        }
    }
}
```

## Limitierungen

- Ein Overlay pro App-Instanz (Singleton Window Manager)
- Für Multiple Overlays: Content in einem ZStack kombinieren
- Window bleibt persistent (wird nicht destroyed, nur hidden)
