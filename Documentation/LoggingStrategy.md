# Logging Strategy

How to log with ButchKit: where, what, and at which level.

## Why we log at all

Logs have exactly one purpose: making the product better and more stable for the person using it. In this order:

1. **See failures.** Notice when something goes wrong for a user, ideally before they report it.
2. **Be ready for a crash.** When the app crashes or ends up in an invalid state, the messages written before it must be enough to understand what happened.
3. **Improve the system.** Turn recurring patterns into targeted fixes.

Logs are not analytics. Usage statistics belong in an analytics tool, not in the log.

## The model

Five things make up every log message. Understand these and you can log.

| Part | Meaning | Who decides |
|---|---|---|
| **Subsystem** | Which app | ButchKit, automatically from the bundle identifier |
| **Category** | Which area of the app | You, once per area: `Camera`, `Audio`, `Purchase` |
| **Level** | How important | You, per message. Decides whether the line survives in the field |
| **Message** | A constant stem plus `key=value` fields | You |
| **Privacy** | Every value is private unless you mark it public | You, deliberately |

Subsystem and category are what you filter by in the console. Level decides whether a message is still there when you need it. The rest is wording.

## Setup

Every app declares its categories in **one dedicated file**, `LoggerCategories.swift`. That file is the registry: the single place where a category comes into existence, and the place where you say what it covers. Nothing else to call at launch, no configuration.

```swift
// LoggerCategories.swift — the one place categories are declared
import ButchKit
import OSLog

nonisolated extension Logger {
    /// Capture session, recording lifecycle, and saving to Photos.
    static let camera   = LoggerService.shared["Camera"]
    /// Audio session configuration and microphone selection.
    static let audio    = LoggerService.shared["Audio"]
    /// Entitlement checks and paywall decisions.
    static let purchase = LoggerService.shared["Purchase"]
}
```

Write the doc comment. It is what lets the next person — or the next agent — pick the right category instead of inventing a near-duplicate. A console filter full of `Camera`, `Capture` and `Recording` is how that goes wrong.

Add a category when an area actually logs, not in advance. An unused category is noise.

### Why `nonisolated`

It is not decoration. As soon as a project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, static properties without it belong to the main actor, and reading them from a background queue is a compile error — which is exactly where capture pipelines, sample buffers and network work live. One keyword on the extension covers the whole file.

Applying `nonisolated` to an extension requires **Swift 6.1 or newer** (SE-0449). In a project that does not use main-actor-by-default it changes no behaviour, so writing it costs nothing there.

### Why a plain extension

The obvious next question is whether a macro could shorten this. It could, by roughly one line per category — and it would cost a `swift-syntax` dependency that pins every consuming app to one version, a trust dialog per project and per version bump, and incompatibility with binary distribution. It would also delete the one place where a category is documented, because the only workable macro form is a list of strings in an attribute. `swift-log` stays macro-free for the same reasons. One readable line per category is the better trade.

## Writing a message

```swift
Logger.camera.notice("Recording started: fps=\(fps, privacy: .public) width=\(width, privacy: .public) height=\(height, privacy: .public)")
Logger.camera.error("Capture start failed: code=\(code, privacy: .public) op=startRecording")
```

The pattern is always the same: **a constant stem, then values as `key=value` fields.**

The stem describes the event and never changes between calls, which is what makes messages groupable and searchable. Values hang off the end as fields rather than being built into the sentence. One message is always one line.

`os.Logger` splits this interpolation into static text and arguments by itself. You get the benefits of structured logging while writing what looks like ordinary interpolation.

Interpolated values must be `CustomStringConvertible`. Numbers, strings and durations are; struct types like `CGSize` are not. Log their parts as separate fields — which reads better anyway — or convert with `String(describing:)`.

Formatting belongs inside the interpolation, never in a string you build beforehand:

```swift
// Costs nothing when the message is dropped
Logger.scroll.debug("Scroll tick: speed=\(speed, format: .fixed(precision: 1))")
```

## Choosing the level

This is the most consequential decision per message, because it decides visibility, persistence, and cost.

| Question | Level | On disk? |
|---|---|---|
| Pure developer tracing, high frequency? | `debug` | Never |
| Nice to know, not essential? | `info` | Only while actively collecting |
| Would I need this in a user's failure report? | `notice` | Yes |
| A real runtime failure at a system boundary? | `error` | Yes, kept longer |
| A broken assumption that points at a bug? | `fault` | Yes, kept longest |

Rules of thumb:

- Anything you might need later is at least `notice`. `debug` and `info` are not there in the field.
- High-frequency tracing — per frame, per match, per sample — is always `debug`.
- Expected but meaningful events and deliberate decisions are `notice`.
- Handled failures at a system boundary are `error`.
- Violated assumptions are `fault`.
- Successful routine operations are not logged above `debug`.

You do not need `#if DEBUG` around log calls. `debug` and `info` are not persisted in release anyway, and building the message is optimised away when nothing consumes it. The level controls visibility.

## Privacy

User data is not negotiable.

```swift
// Never: user content in a log
Logger.script.notice("Script: \(text)")

// Instead: derived values that cannot be traced back
Logger.script.notice("Script loaded: words=\(wordCount, privacy: .public) locale=\(locale, privacy: .public)")
```

- Interpolated values are **private by default** and appear as `<private>` outside the debugger. Keep that default.
- Mark a value `public` only when it can never contain personal data: a locale identifier, a duration, a counter, an error code.
- Anyone with the device and its passcode can read these logs. Nothing personal belongs in a `public` value.
- To correlate equal values without revealing them, use `privacy: .private(mask: .hash)`.
- System error text (`error.localizedDescription`) is fine as `public`, as long as it cannot carry user content.

When in doubt, do not log it.

## The readability test

Every message has to stand on its own. Someone who sees only that one line, without knowing the code, must understand:

- **what** happened
- **where** in the system
- in **which flow**
- with **which values**
- and for failures: **why**

A line you can only decode by opening the source fails the test and needs rewriting.

## Wording

Log messages are text humans read. They are written with the same care as the app's UI copy, and they must be understandable to everyone on the team, not just to whoever wrote them.

The counterexample is the classic bad error message: "An error occurred (6383)." It says neither what happened, nor where, nor why.

- **US English**, like code and comments. Log messages are never localised.
- **Specific over generic.** Name the actual operation and object. Not "Operation failed" but "Audio session activation failed".
- **Codes are a field, never the whole message.** `code=…` may travel along, but it never replaces the description in words.
- **Calm and factual.** No drama, no blame, no exclamation marks.
- **Active and concrete.** Say what actually happened.
- **The product's own vocabulary.** Use the words the UI uses, so the whole team talks about the same things.
- **No filler.** Every word carries meaning or goes.
- **No emoji.** They do not help filtering and hurt readability. Category and level already provide the framing.

| Situation | Poor | Good |
|---|---|---|
| Recognizer unavailable | `print("⚠️ not available")` | `Speech recognizer unavailable: locale=\(id, privacy: .public)` |
| Audio session fails | `An error occurred (6383)` | `Audio session activation failed: code=\(err, privacy: .public) op=startRecording` |
| Locale fallback | `fallback en-US` | `Locale fallback: requested=\(code, privacy: .public) resolved=en-US reason=noOnDeviceSupport` |
| Missing permission | `not authorized` | `Speech permission denied: cannot start recording` |
| Recording ended | `[AS] stopped` | `Recording stopped: duration=\(seconds, privacy: .public)s` |

## What we log

- Decisions with their reason — which option was chosen and why a fallback kicked in.
- State transitions of stateful engines.
- Events at system boundaries that can fail: permissions, audio sessions, file access, network, purchases.
- The lifecycle of a long-running operation: start, end, and a summary.
- Failures with enough context to act on them.

## What we never log

- User content or any other user input.
- Success spam for routine operations.
- High-frequency diagnostics at a persisted level.
- Multi-line messages.
- Anything that serves none of the three purposes at the top.

## Correlating a flow

A single user action often crosses several areas. Carry one `LogSession` through them so the whole run can be filtered as one flow:

```swift
let session = LogSession()

Logger.camera.notice("Recording started: session=\(session.id, privacy: .public)")
Logger.speech.notice("Recognition started: session=\(session.id, privacy: .public)")
Logger.camera.notice("Recording stopped: session=\(session.id, privacy: .public) duration=\(seconds, privacy: .public)s")
```

Filtering the console for `session=a3f9` now shows that one recording across every category, instead of reading each area separately.

The identifier is interpolated explicitly. `os.Logger` takes a message the compiler assembles at the call site, so nothing can be appended afterwards without giving up privacy annotations and lazy formatting. Always write `\(session.id, privacy: .public)`.

## Logging from a view

Views can read the logger from the environment. It works without any setup:

Name the category in `LoggerCategories.swift` as well, so it stays findable next to the others:

```swift
// LoggerCategories.swift
nonisolated extension LogCategory {
    /// Entitlement checks and paywall decisions.
    static let purchase: Self = "Purchase"
}
```

```swift
struct PaywallView: View {
    @Environment(\.log) private var log

    var body: some View {
        PaywallContent()
            .onAppear {
                log[.purchase].notice("Paywall presented: source=onboarding")
            }
    }
}
```

The environment only changes how you reach the logger, not where categories are declared. It exists only inside a view body — services, actors and background queues use the static logger from the setup section, which is where most logging happens anyway.

To point a view hierarchy at a different subsystem, set the value like any other: `.environment(\.log, LoggerService(subsystem: "com.host.app"))`.

## Reading logs

While developing, the Xcode console filters by category and level. For a test device outside Xcode, use the Console app and filter by subsystem and category. `notice` and above are visible by default; `info` and `debug` have to be switched on.

## Exporting logs

`LogExport` reads the app's own messages back, for example to attach them to a bug report:

```swift
struct DiagnosticsView: View {
    @State private var report: URL?
    @State private var failure: String?

    var body: some View {
        VStack {
            Button("Prepare diagnostics") {
                Task {
                    discard()
                    do {
                        report = try await LogExport.fileURL(since: .now.addingTimeInterval(-3600))
                        failure = nil
                    } catch {
                        failure = error.localizedDescription
                    }
                }
            }

            if let report {
                ShareLink("Share diagnostics", item: report)
            }

            if let failure {
                Text(failure).foregroundStyle(.secondary)
            }
        }
        .onDisappear(perform: discard)
    }

    /// The exported file is ours to clean up — see below.
    private func discard() {
        if let report { try? FileManager.default.removeItem(at: report) }
        report = nil
    }
}
```

Handle the error rather than swallowing it with `try?`. `fileURL` throws `LogExportError.noEntries` when nothing matched the window, which is the *common* case: the app was relaunched, or the target logs under a different subsystem. Better to tell the user that than to hand them an attachment with nothing in it.

`fileURL` writes a plain text file named `VideoSkript-Diagnostics-2026-08-05-1431-a3f91b2c.txt` and hands you its URL. The app name comes from the bundle, so there is nothing to configure and nothing to keep in sync when you rename the app. Share the URL, not the text: a shared string is pasted into the message body, a shared file arrives as an attachment — the difference between a report someone can open and one they have to scroll past. Every call writes its own file, so two shares can be open at once; delete it once the share sheet is done.

Two more shapes exist for the same content. `LogExport.text(since:from:)` returns a string, for showing the log on screen. `LogExport.entries(since:from:)` returns structured values, for filtering or listing them.

The export filters by subsystem, so it has to read the same one you wrote to. If a target logs through its own service — an app extension using the host app's subsystem — pass that service in, otherwise the report comes back empty and nothing warns you:

```swift
let service = LoggerService(subsystem: "com.host.app")
let report  = try await LogExport.text(since: .now.addingTimeInterval(-3600), from: service)
```

Two limits shape what this feature can be:

- **Only the running launch.** The system scopes the export to the current process. After a relaunch the process is a different one, so messages from before a crash are out of reach. Sending logs *while* a bug is happening works; sending them *after* a crash does not.
- **`debug` and `info` are usually gone.** They live in an in-memory buffer and are not written to disk. Expect `notice`, `error` and `fault`.

Both sharpen the same rule: anything you may need later has to be logged at `notice` or above.

## Rules for agents

A compact checklist for anyone — human or AI — writing log statements in a ButchKit project:

- Never use `print` or `NSLog` for diagnostics. Always `os.Logger`.
- Declare categories only in `LoggerCategories.swift`, as `static let` on `Logger`, each with a `///` comment saying what it covers. Never add one anywhere else.
- Never call `LoggerService.shared[…]` inside a loop or a hot path.
- Constant stem first, then `key=value` fields. One line per message.
- Never mark a value `public` if it can contain user data.
- Use `notice` or higher for anything that must be visible in the field.
- No emoji, no drama, US English.
- Put formatting inside the interpolation, never in a prebuilt string.
- Add a category only when an area actually logs.
