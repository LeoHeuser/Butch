# In-App Notification System

Ein simples, natives Notification-System für SwiftUI Apps, das Benachrichtigungen am oberen Bildschirmrand anzeigt - immer über allen anderen UI-Elementen.

## Übersicht

Das In-App Notification System zeigt temporäre Benachrichtigungen an, die über Sheets, Alerts und allen anderen UI-Elementen erscheinen. Es nutzt den `alwaysOnTopOverlay` Modifier für z-ordering und bleibt dabei 100% SwiftUI für UI, Animationen und Interaktionen.

## Setup

Einmalig im Root View der App:

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
        Button("Speichern") {
            saveData()

            inAppNotification.send(InAppNotificationObject(
                title: "Gespeichert",
                message: "Deine Änderungen wurden gespeichert",
                systemImage: "checkmark.circle.fill"
            ))
        }
    }
}
```

## API

### InAppNotificationObject

Beschreibt eine Notification:

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

Observable Service zum Senden von Notifications:

```swift
@Observable
@MainActor
public class InAppNotificationService {
    public var currentNotification: InAppNotificationObject?
    public func send(_ notification: InAppNotificationObject)
}
```

## Verhalten

### Auto-Dismiss
Notifications werden automatisch nach 3 Sekunden ausgeblendet.

### Manuelle Interaktion
- **Tap**: Notification antippen → sofort schließen
- **Swipe Up**: Nach oben wischen → sofort schließen

### Animationen
- **Einblenden**: Slide from top + Fade in
- **Ausblenden**: Slide to top + Fade out
- **Timing**: Spring animation (.spring)

### Z-Ordering
Notifications erscheinen **IMMER** über:
- Sheets (`.sheet()`)
- Alerts (`.alert()`)
- Full Screen Covers (`.fullScreenCover()`)
- Allem anderen

## Design

### Layout
- **Position**: Oben, zentriert
- **Safe Area**: Wird respektiert (erscheint unterhalb Notch/Dynamic Island)
- **Padding**: 8pt oben, 16pt horizontal

### Stil
- **Background**: `.thinMaterial` (Glasmorphism)
- **Border**: `.separator` Stroke
- **Corner Radius**: 32pt
- **Typografie**:
  - Titel: `.headline`
  - Message: `.body`
  - Icon: `.title2`

### Spacing
- Icon ↔ Titel: `.spacingS`
- Titel ↔ Message: `.spacingS`

## Beispiele

### Einfache Notification

```swift
inAppNotification.send(InAppNotificationObject(
    title: "Fertig!"
))
```

### Mit Nachricht

```swift
inAppNotification.send(InAppNotificationObject(
    title: "Upload abgeschlossen",
    message: "Dein Video wurde erfolgreich hochgeladen"
))
```

### Mit Icon

```swift
inAppNotification.send(InAppNotificationObject(
    title: "Fehler",
    message: "Die Datei konnte nicht geladen werden",
    systemImage: "exclamationmark.triangle.fill"
))
```

### Lokalisierung

```swift
inAppNotification.send(InAppNotificationObject(
    title: "notification.saved.title",
    message: "notification.saved.message",
    systemImage: "checkmark.circle.fill"
))
```

## Technische Details

### Architektur
- **Service**: `@Observable` Class, verwaltet `currentNotification`
- **Component**: SwiftUI View, rendert die Notification
- **Overlay**: Nutzt `alwaysOnTopOverlay` für z-ordering
- **Platform**: iOS 17+, macOS 14+

### Environment
Der Service wird automatisch ins SwiftUI Environment injiziert via `.setupInAppNotifications()`. Alle Child-Views können ihn über `@Environment` abrufen.

### Performance
- **Lazy Creation**: Overlay-Window wird erst bei erster Notification erstellt
- **Persistence**: Window bleibt persistent (hidden wenn keine Notification)
- **Memory**: Minimal Overhead (ein Service, ein Window)
- **CPU**: Updates nur bei Notification-Änderungen

### UIKit Bridge
Minimal: Nur `windowLevel` für z-ordering. Alle UI, Animationen und Gestures in SwiftUI.
