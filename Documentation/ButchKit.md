# ButchKit

A lean SwiftUI component library extending native Apple platform patterns.

ButchKit collects the small pieces that most apps end up rebuilding: view modifiers, colour helpers, and services that wrap system frameworks in a way that stays close to the platform. Everything is built on native APIs — the library adds ergonomics, never a layer you have to learn instead of Apple's.

Platform support: iOS/iPadOS 17.0+ and macOS 14.0+. Builds with Swift 6.2 or newer (Xcode 26+).

## Documents

Prose that applies across the library. These are binding for how we build, not descriptions of what exists.

- [Logging Strategy](LoggingStrategy.md) — where, what, and at which level we log.
- [Paywall](Paywall.md) — how an app sells its subscription: setup, gating, presenting, analytics.

## What's in the library

Every type is documented in code. This is the map.

### Logging

`Sources/ButchKit/Services/LoggerService/`

- `Logger.init(category:subsystem:)` — how an app declares a category. Resolves the subsystem itself.
- `LoggerService` — binds a group of loggers to one subsystem, for app extensions, tests and export.
- `LogCategory` — the area of the app a message belongs to.
- `LogSession` — a short identifier that ties one flow together across categories.
- `LogExport`, `LogEntry`, `LogLevel` — reading the app's own logs back for a bug report.
- `EnvironmentValues.log` — the logger inside a SwiftUI view.

### User-facing errors

`Sources/ButchKit/Services/UFEService/`

- `UFEService` — collects errors from anywhere and surfaces them through one native alert.
- `UFError`, `UFErrorLevel` — the shape an error needs to be presentable.
- `View.userFacingErrors(_:)` — root-level integration.

### Paywall

`Sources/ButchKit/Services/PaywallService/`

- `View.paywallEnvironment(_:features:)` — root-level integration. Creates the service, injects it and attaches the paywall sheet.
- `PaywallService` — `hasSubscription`, fed by StoreKit 2, plus `present(source:)` and `require(source:_:)` to show the paywall from anywhere.
- `PaywallConfiguration` — the subscription group and policy URLs.
- `PayWallFeature` — one marketing page: title, description, image.
- `PaywallEvent` — the funnel, forwarded through `PaywallService.onEvent` to the app's analytics.
- `PaywallRequest` — the presentation in flight.
- `PaywallStatusRow` — the settings row: subscription status and management, or the offer.
- `View.paywallSheet()` — reinforcement for views that are themselves sheets.

### General utility

`Sources/ButchKit/General Utility/`

- `StaticWebView` — a web view for fixed, trusted content.
- `WebViewButton` — a button that presents one.
- `View.sheetDismissButton()` — a native close button for sheets.
- `View.useContentHeightPresentationDetent` — sizes a sheet to its content.
- `View.onShake(isEnabled:respectsShakeToUndoSetting:perform:)` — runs an action when the device is shaken (iOS only).

### Token utility

`Sources/ButchKit/Token Utility/`

- `Color.adaptiveColor(...)` — a colour that resolves per platform.
