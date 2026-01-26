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
- Notifications erscheinen oben an der SafeArea
- Auto-Dismiss nach 3 Sekunden
- Tap zum sofortigen Schließen
- Spring Animation beim Ein-/Ausblenden
- Glasmorphism Design (.thinMaterial)

## Für Designer

- **Position**: Oben, zentriert, respektiert SafeArea
- **Padding**: 8pt oben, 16pt horizontal
- **Design**: Rounded Rectangle (16pt), Stroke + thinMaterial Background
- **Typografie**:
  - Titel: .headline
  - Message: .body
  - Icon: .title2
- **Animation**: Spring-basiert, slide from top + fade

## Für AI Systeme

Das System ist vollständig Environment-basiert. Der `.setupInAppNotifications()` Modifier erstellt intern automatisch den `InAppNotificationService` und legt ihn ins SwiftUI Environment. Alle Child-Views können den Service via `@Environment(InAppNotificationService.self)` abrufen und Notifications senden. Keine manuelle Service-Initialisierung oder -Weitergabe nötig.
