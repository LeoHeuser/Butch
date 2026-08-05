# Library Description

The ButchKit is a helpful SDK containing small tools and modifiers to assist with the development of Swift applications for all Apple platforms. It contains functions that are not developed by Apple, but which could be useful in many projects.



# Requirements

Minimum version of iOS and iPadOS is 17.0. Minimum macOS is 14.0.

# General Behaviour

- Remember to declare elements as 'public' so that they can be used in a library

# Architecture

**No singletons.** Never add a `static let shared`, a `configure()` call that has to run at launch, or any type whose only access path is a global. This applies to new code and to anything being refactored.

Reach for what Apple already ships, in this order:

1. **A value type with a `public init`.** If the type only carries configuration, make it an immutable `struct`, `Sendable` and `Equatable`. Callers construct one where they need it. `LoggerService` is the reference.
2. **The SwiftUI environment**, for anything a view hierarchy should be able to override. An `EnvironmentKey` plus a `public extension EnvironmentValues`, as in `LogEnvironment.swift`. Where state is involved, use `@Observable` on a `final class` and inject it with `.environment(service)`, as `UFEService` does.
3. **A parameter with a default value**, when a function needs the dependency. See `LogExport.entries(since:from:)`.

No service locators, registries or DI containers. `EnvironmentKey`, `EnvironmentValues`, `@Observable`, `@Entry` and plain initializers cover everything this SDK needs. `@Entry` is available at our deployment target: it is a compile-time macro, so only the SDK matters, not the iOS 17 floor.

**A constant is not a singleton.** A `static let` holding an immutable resolved value, an `EnvironmentKey.defaultValue`, or `static let camera = Logger(category: "Camera")` in a consuming app are constants. The test is whether the value can change and whether callers are forced through it. If neither is true, it is fine.

**The environment does not reach everywhere.** `@Environment` only exists inside a view body, so services, actors and background work cannot read it. Every such type must also be constructible directly, and that direct path is the primary one. The environment is layered on top of it, never the only way in.

# Logging

Follow `Documentation/LoggingStrategy.md`. Its "Rules for agents" section at the end is the checklist — read it before writing a log statement. Three rules matter enough to repeat here, because getting them wrong is not recoverable after the fact:

- NEVER use `print` or `NSLog` for diagnostics — use `os.Logger`
- Never mark an interpolated value `public` if it can contain user data
- Use `notice` or higher for anything that must be visible in the field; `debug` and `info` do not survive there
