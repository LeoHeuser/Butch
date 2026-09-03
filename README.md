# ButchKit

A lean SwiftUI component library extending native Apple platform patterns.

**Platform Support**: iOS/iPadOS 17.0+ and macOS 14.0+
**Toolchain**: Swift 6.2 or newer (Xcode 26+)

## Installation

### Swift Package Manager

In Xcode:
1. **File** → **Add Package Dependencies…**
2. Enter the URL: `https://github.com/LeoHeuser/ButchKit`
3. Click **Add Package**

Or add it to your `Package.swift` dependencies:

```swift
dependencies: [
.package(url: "https://github.com/LeoHeuser/ButchKit", from: "1.0.0")
]
```

## Documentation

Each component or element in this SDK is documented in code.

Prose that applies across the library lives in [`Documentation/`](Documentation/ButchKit.md):

- [Logging Strategy](Documentation/LoggingStrategy.md) — where, what, and at which level we log.
- [Paywall](Documentation/Paywall.md) — how an app sells its subscription: setup, gating, presenting, analytics.

## Localization

ButchKit ships no strings. Every key it renders resolves in your app's catalog, so a consuming app
needs at least `Localizable.xcstrings` and `Errors.xcstrings` -- errors come from the second one.
See [Localization](Documentation/ButchKit.md#localization) for which string goes where.
