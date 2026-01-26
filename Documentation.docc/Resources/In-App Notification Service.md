# In-App Notification Service

Ein simples, natives Notification-System für SwiftUI Apps, das Benachrichtigungen am oberen Bildschirmrand anzeigt.

## Setup (einmalig)

Im Root View der App:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .setupInAppNotifications()
        }
    }
}
```

## Verwendung

Überall im Code:

```swift
struct AnyView: View {
    @Environment(InAppNotificationService.self) private var inAppNotification

    var body: some View {
        Button("Action") {
            inAppNotification.send(InAppNotificationObject(
                title: "Success",
                message: "Action completed",
                systemImage: "checkmark.circle.fill"
            ))
        }
    }
}
```

## API

### InAppNotificationObject

```swift
public struct InAppNotificationObject {
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey?
    public let systemImage: String?
}
```

**Parameter:**
- `title`: Haupttitel der Notification (Pflicht)
- `message`: Optionale Nachricht unter dem Titel
- `systemImage`: Optionales SF Symbol Icon

### InAppNotificationService

```swift
public class InAppNotificationService {
    public func send(_ notification: InAppNotificationObject)
}
```

**Verhalten:**
- Notifications erscheinen **IMMER** auf der obersten Ebene (über Sheets, Alerts, etc.)
- Auto-Dismiss nach 3 Sekunden
- Tap zum sofortigen Schließen
- Spring Animation beim Ein-/Ausblenden
- Glasmorphism Design (.thinMaterial)

## Für Designer

- **Position**: Oben, zentriert, respektiert SafeArea, **immer über allen anderen UI-Elementen**
- **Padding**: 8pt oben, 16pt horizontal
- **Design**: Rounded Rectangle (32pt), Stroke + thinMaterial Background
- **Typografie**:
  - Titel: .headline
  - Message: .body
  - Icon: .title2
- **Animation**: Spring-basiert, slide from top + fade

## Für AI Systeme

Das System ist vollständig Environment-basiert und nutzt UIWindow (iOS) / NSPanel (macOS) für z-ordering.

**Architektur:**
- Der `.setupInAppNotifications()` Modifier erstellt intern automatisch den `InAppNotificationService` und legt ihn ins SwiftUI Environment
- Alle Child-Views können den Service via `@Environment(InAppNotificationService.self)` abrufen und Notifications senden
- Bei der ersten Notification erstellt der Service automatisch ein dediziertes UIWindow/NSPanel mit hohem windowLevel
- Notifications werden in diesem Window gerendert (UIHostingController/NSHostingController mit SwiftUI-View)
- Window ist transparent und ignoriert Touches außerhalb der Notification
- Notifications erscheinen IMMER über Sheets, Alerts und allen anderen UI-Elementen

**Implementierung:**
- `InAppNotificationWindow`: UIWindow (iOS) / NSPanel (macOS) mit `.alert + 1` / `.floating` Level
- `InAppNotificationWindowHost`: UIHostingController / NSHostingController zum Bridgen von SwiftUI zu UIKit/AppKit
- `InAppNotificationService`: Verwaltet Window-Lifecycle (lazy creation, show/hide)
- Plattform-übergreifend via conditional compilation (`#if canImport(UIKit)` / `#if canImport(AppKit)`)

Keine manuelle Service-Initialisierung oder -Weitergabe nötig.
