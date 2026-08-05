# ButchKit

A lean SwiftUI component library extending native Apple platform patterns.

ButchKit collects the small pieces that most apps end up rebuilding: view modifiers, colour helpers, and services that wrap system frameworks in a way that stays close to the platform. Everything is built on native APIs — the library adds ergonomics, never a layer you have to learn instead of Apple's.

Platform support: iOS/iPadOS 17.0+ and macOS 14.0+. Builds with Swift 6.2 or newer (Xcode 26+).

## Documents

Prose that applies across the library. These are binding for how we build, not descriptions of what exists.

- [Logging Strategy](LoggingStrategy.md) — where, what, and at which level we log.

## What's in the library

Every type is documented in code. This is the map.

### Logging

`Sources/ButchKit/Services/LoggerService/`

- `LoggerService` — vends `os.Logger` instances, resolves the subsystem once.
- `LogCategory` — the area of the app a message belongs to.
- `LogSession` — a short identifier that ties one flow together across categories.
- `LogExport`, `LogEntry`, `LogLevel` — reading the app's own logs back for a bug report.
- `EnvironmentValues.log` — the logger inside a SwiftUI view.

### User-facing errors

`Sources/ButchKit/Services/UFEService/`

- `UFEService` — collects errors from anywhere and surfaces them through one native alert.
- `UFError`, `UFErrorLevel` — the shape an error needs to be presentable.
- `View.userFacingErrors(_:)` — root-level integration.

### General utility

`Sources/ButchKit/General Utility/`

- `StaticWebView` — a web view for fixed, trusted content.
- `WebViewButton` — a button that presents one.
- `View.sheetDismissButton()` — a native close button for sheets.
- `View.useContentHeightPresentationDetent` — sizes a sheet to its content.

### Token utility

`Sources/ButchKit/Token Utility/`

- `Color.adaptiveColor(...)` — a colour that resolves per platform.
