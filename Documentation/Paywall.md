# Paywall

How to sell a subscription with ButchKit: one configuration, one modifier, one question everywhere else.

## What it is

Every app we ship earns its money through one auto-renewable subscription group. The paywall module turns that into a fixed system so an app never writes StoreKit code again:

1. **One truth.** `PaywallService.hasSubscription` is the only place that knows whether the user pays. Every gate in the app asks it, nothing else.
2. **One integration.** `.paywallEnvironment(_:features:)` on the root view. It creates the service, injects it, runs the first entitlement check and owns the paywall sheet.
3. **One look.** The paywall is the VideoSkript layout: full-bleed photo pages that advance on their own, over Apple's `SubscriptionStoreView`. Apps supply pages, not views.

The paywall is not a place for experiments. If the layout has to change, it changes in ButchKit for every app.

## The model

| Part | Meaning | Who decides |
|---|---|---|
| **`PaywallConfiguration`** | The subscription group and the two policy URLs | You, once per app |
| **`PayWallFeature`** | One marketing page: a title, plus an optional description and photo | You, once per app, as many as you like |
| **`PaywallService`** | `hasSubscription`, plus `present` and `require` to show the paywall | ButchKit, created by the root modifier |
| **`PaywallEvent`** | The funnel: presented, purchase started, completed, pending, failed | ButchKit reports, you forward to analytics |
| **`PaywallRequest`** | The presentation in flight, carrying its `source` | ButchKit |
| **`PaywallStatusRow`** | The settings row: status and management, or the offer | ButchKit |

Entitlement is decided per **subscription group**, not per product. Every tier in the group unlocks the app. Adding a monthly tier next to the yearly one is an App Store Connect change, not a code change.

## Setup

Every app declares its paywall in **one dedicated file**, `Paywall.swift`. That file is the whole definition: which group, which URLs, which pages.

```swift
// Paywall.swift — the one place the paywall is defined
import ButchKit

#if DEBUG
private let groupID = "48E92801"   // the group in Products.storekit
#else
private let groupID = "21900977"   // the group in App Store Connect
#endif

let paywallConfig = PaywallConfiguration(
    subscriptionGroupID: groupID,
    privacyPolicyURL: "https://heuser.design/app/privacy",
    termsOfServiceURL: "https://heuser.design/app/terms"
)

let paywallFeatures: [PayWallFeature] = [
    PayWallFeature(title: "paywall.feature.1.title",
                   description: "paywall.feature.1.description",
                   image: .payWallFeature1),
    PayWallFeature(title: "paywall.feature.2.title",
                   description: "paywall.feature.2.description",
                   image: .payWallFeature2),
]
```

Only the title is required. Leave out `image` and the page shows its text centred on the paywall's dark ground; leave out `description` and the title stands on its own. A page with a photo keeps its text at the bottom, where the photo has faded out.

Then one modifier on the root view, above everything that might gate a feature or show the paywall:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .paywallEnvironment(paywallConfig, features: paywallFeatures)
        }
    }
}
```

That is the complete setup. There is nothing to call at launch and no service to store.

Put the modifier on a view whose body does not re-evaluate often. Inside `WindowGroup` as shown is right; `@State` inside the modifier keeps one service alive for the life of the scene.

The group identifier differs between the local `.storekit` file and App Store Connect, hence the `#if DEBUG`. Keep the `.storekit` file wired into the Run scheme so the paywall works in the simulator.

## Reading the state

Anywhere below the root, the service is a native environment value:

```swift
struct EditorView: View {
    @Environment(PaywallService.self) private var paywall

    var body: some View {
        if paywall.hasSubscription {
            EditableText()
        } else {
            LockedText { paywall.present(source: "lockedScript") }
        }
    }
}
```

`hasSubscription` is `@Observable`. A view that reads it re-renders when the subscription changes, including a restore or a renewal that lands while the view is on screen.

`isInitialized` turns `true` after the first entitlement check. Hold a launch gate on it only if the very first screen depends on the subscription. Because the last known state is cached, a subscriber sees no paywall flash even before it turns `true`.

## Showing the paywall

Two calls, both from anywhere:

```swift
// Show it. The user decides what to do next.
paywall.present(source: "settings")

// Gate an action. Runs now when subscribed; otherwise shows the paywall and runs the
// action right after the purchase, so the user lands where they were going.
Button("button.newScript", systemImage: "plus") {
    paywall.require(source: "newScript") { addScript() }
}
```

`require` is the default for anything the user *does*. `present` is for places that only *show* the offer: a Settings row, a locked hint. Closing the paywall without buying drops the deferred action, nothing runs behind the user's back.

`source` is the app's own short name for where the user hit the lock: `newScript`, `lockedScript`, `pasteButton`, `settings`. It is carried on every event, so analytics can tell which entry point earns the conversions. Use `lowerCamelCase`, keep the set small, and keep it stable across releases.

No view declares a sheet. The root modifier owns it.

### Views that are sheets themselves

SwiftUI presents one sheet per view. While a Settings sheet is open, the root sheet cannot appear on top of it, so a `present` from inside Settings would go nowhere. Apply `.paywallSheet()` once to the content of any sheet that can trigger the paywall:

```swift
.sheet(isPresented: $showsSettings) {
    SettingsView()
        .paywallSheet()
}
```

Views pushed onto a `NavigationStack` need nothing. Only full sheets and covers do.

### The settings row

Every app needs one place that says what the user is paying for. Apple expects a path to the
system's subscription management, and a subscriber who cannot find out what they bought writes
to support instead of looking it up.

```swift
Form {
    CloudStatus()

    Section {
        PaywallStatusRow(source: "settings")
    }

    LegalInfo()
}
```

One row, two states, both of which lead somewhere: a subscriber gets the way into the system's
management, everybody else gets the offer through `present`. Nothing to configure and no state
to pass in. On iOS the management opens as `manageSubscriptionsSheet`; on macOS, which has no
such sheet, the button opens the App Store's subscription page.

## What the user sees

The paywall is fixed. For every app:

- Photo pages from `paywallFeatures`, swipeable, advancing every five seconds, pausing for fifteen after a swipe. Page dots are always visible.
- Title in `.title.bold`, description in `.headline`. On a page with a photo the text sits at the bottom, over a gradient that fades the photo out; on a page without one it centres.
- Apple's subscription controls below. One plan in the group shows a single Subscribe button; several show Apple's picker with one Subscribe button under it. StoreKit picks that from the group itself, so adding a tier in App Store Connect needs no code change. Introductory offers are shown by StoreKit either way.
- Restore Purchases, and Privacy Policy plus Terms of Service when both URLs are configured. Policies open in `StaticWebView` inside the sheet.
- A close button in the toolbar. Dark appearance regardless of the device setting.
- On success the sheet closes on its own. On failure a native alert.

Shoot or grade the photos for a dark ground; text is white on them.

## Hiding or paywalling

Not everything that needs a subscription belongs behind the paywall. The rule from VideoSkript:

- **Paywall** the thing the subscription sells. Creating and editing.
- **Hide** what would trap a free user. Rename and delete of their own data are hidden, not paywalled: deleting your only script and then being unable to create one is no reason to be sold a subscription.
- **Read-only** instead of disabled. A locked text stays scrollable; a disabled `TextEditor` would make a long script unreadable.

## Analytics

ButchKit has no analytics dependency. Assign `onEvent` once, in the root view, and forward:

```swift
struct RootView: View {
    @Environment(PaywallService.self) private var paywall

    var body: some View {
        ContentView()
            .onAppear {
                paywall.onEvent = { event in
                    switch event {
                    case .presented(let source):
                        TelemetryDeck.signal("paywall.presented", parameters: ["paywall.trigger": source])
                    case .purchaseStarted(let source):
                        TelemetryDeck.signal("paywall.purchaseInitiated", parameters: ["paywall.trigger": source])
                    case .purchaseCompleted(let source):
                        TelemetryDeck.signal("paywall.completed", parameters: ["paywall.trigger": source])
                    case .purchasePending, .purchaseFailed:
                        break
                    case .verificationFailed:
                        TelemetryDeck.signal("purchase.verificationFailed")
                    }
                }
            }
    }
}
```

`presented` is the funnel's denominator, `purchaseCompleted` the numerator. A free trial start counts as completed. Restores and renewals are deliberately not events: they arrive through `Transaction.updates`, not through the paywall, and would inflate the conversion rate.

## Localization

ButchKit ships no strings. Every key resolves in the app's own string catalog, so the paywall speaks every language the app does. An app must define:

| Key | Used for |
|---|---|
| `paywall.feature.n.title`, `paywall.feature.n.description` | Your pages, any keys you choose |
| `error.paywall.purchaseFailed.title` | Alert title after a failed purchase |
| `error.paywall.purchaseFailed.message` | Alert message after a failed purchase |
| `webView.privacyPolicy.title` | Navigation title of the privacy policy page |
| `webView.termsOfUse.title` | Navigation title of the terms page |
| `button.dismissSheet` | The close button, shared with `View.sheetDismissButton()` |
| `paywall.status.subscribed` | The settings row's label while subscribed, usually the plan's name |
| `paywall.status.unsubscribed` | The settings row while not subscribed, which opens the paywall |
| `button.manageSubscription` | The settings row's way into the system's subscription management |

Product names and prices come from App Store Connect, localized per storefront. Never hardcode a price in a marketing page.

## What happens underneath

- **Launch.** The cached answer from the last run is restored immediately. `Transaction.currentEntitlements` is then read once; a verified transaction in the configured group means subscribed. `isInitialized` turns `true`.
- **While running.** From `initialize()` on, a `Transaction.updates` listener finishes every verified transaction and updates the state: purchase, renewal, restore, Ask to Buy approval, and refund or revocation, which clears access immediately.
- **Foreground.** Call `await paywall.refresh()` from the root's `scenePhase` handler if a lapsed subscription should lock the app without waiting for the next update. Not required for correctness.
- **Offline.** StoreKit 2 answers entitlement checks from its own local cache, so a subscriber keeps access without a network. Online, StoreKit's answer is definitive: no entitlement means no access.
- **Verification failures.** Unverified transactions are not finished, as Apple recommends. They are logged and reported as `.verificationFailed`.
- **Logging.** Under the app's own subsystem, category `Purchase`. `notice` for a cleared or revoked subscription, `error` for failures, `debug` for each resolved check. See `LoggingStrategy.md`.

## What it does not do

Deliberately, to stay one system:

- **No lifetime or consumable products.** One auto-renewable group only. `SubscriptionStoreView` cannot show a non-consumable next to subscriptions, and two purchase paths mean two paywalls.
- **No custom grace period.** Billing retry and grace belong to App Store Connect (Subscription Group settings), not to the app.
- **No product loading.** The paywall fetches its own products. An app that wants the localized product name for a Settings row calls `Product.products(for:)` itself.
- **No promo, win-back or offer codes.** Add them in App Store Connect; StoreKit surfaces the eligible ones in the paywall on its own.

## Testing

- **Unit tests** cover the service's presentation logic: `present`, `require`, deferred actions, cache restore. StoreKit itself is not reachable from a package test.
- **In the app**, run with the `.storekit` file: buy, check the sheet closes and the gate opens, relaunch and confirm there is no flash, Restore Purchases, and refund in Xcode's Transactions manager to see access clear.
- **Sheet-in-sheet**: open the paywall from a root view and from inside a presented sheet with `.paywallSheet()`. Both must appear.

## Rules for agents

A compact checklist for anyone, human or AI, touching the paywall in a ButchKit project:

- The paywall is defined in `Paywall.swift` and installed once with `.paywallEnvironment(_:features:)` on the root. Nowhere else.
- Never construct or store a `PaywallService` in app code. Read it with `@Environment(PaywallService.self)`.
- Gate on `paywall.hasSubscription`. Never read StoreKit, `Transaction` or `UserDefaults` for the subscription state.
- Use `require(source:_:)` for actions, `present(source:)` for offers. Never declare a paywall sheet in a view.
- Apply `.paywallSheet()` inside every sheet or cover that can trigger the paywall. Nothing on pushed views.
- Hide what would trap a free user; paywall only what the subscription sells.
- Configure by subscription group, never by product identifier. Debug and Release group IDs differ.
- Marketing pages are `PayWallFeature` values, never custom views. The layout is fixed in ButchKit.
- All paywall strings are keys in the app's catalog, including the feature titles.
- Forward `PaywallEvent` to analytics from one place. Never track a restore or renewal as a conversion.
- Never add products other than auto-renewable subscriptions, a grace period, or network checks to the service.
