import Foundation
import Testing
@testable import ButchKit

@Suite("PaywallConfiguration")
struct PaywallConfigurationTests {
    @Test("Leaves the policy URLs empty by default")
    func defaults() {
        let config = PaywallConfiguration(subscriptionGroupID: "1")
        #expect(config.privacyPolicyURL == nil)
        #expect(config.termsOfServiceURL == nil)
        #expect(!config.hasPolicies)
    }

    /// StoreKit shows the privacy and terms buttons as a pair, so one missing URL must hide both
    /// rather than leave a button that leads nowhere.
    @Test("Shows policies only when both URLs are set")
    func policiesNeedBothURLs() {
        #expect(!PaywallConfiguration(subscriptionGroupID: "1", privacyPolicyURL: "a.com").hasPolicies)
        #expect(!PaywallConfiguration(subscriptionGroupID: "1", termsOfServiceURL: "b.com").hasPolicies)
        #expect(PaywallConfiguration(subscriptionGroupID: "1", privacyPolicyURL: "a.com", termsOfServiceURL: "b.com").hasPolicies)
    }
}

@Suite("PaywallService", .serialized)
@MainActor
struct PaywallServiceTests {
    private let config = PaywallConfiguration(subscriptionGroupID: "TEST")

    /// The cache survives between test runs in the host's defaults; every test starts unsubscribed.
    private func makeService() -> PaywallService {
        UserDefaults.standard.removeObject(forKey: PaywallService.cacheKey)
        return PaywallService(configuration: config)
    }

    @Test("Starts uninitialized with its configuration")
    func initialState() {
        let service = makeService()
        #expect(!service.isInitialized)
        #expect(service.configuration == config)
        #expect(service.features.isEmpty)
        #expect(service.presentedRequest == nil)
    }

    @Test("Forwards events to onEvent")
    func reportsEvents() {
        let service = makeService()
        var received: [PaywallEvent] = []
        service.onEvent = { received.append($0) }
        service.report(.presented(source: "settings"))
        #expect(received == [.presented(source: "settings")])
    }

    @Test("Presents and dismisses")
    func presentAndDismiss() {
        let service = makeService()
        service.present(source: "settings")
        #expect(service.presentedRequest?.source == "settings")
        service.dismissPaywall()
        #expect(service.presentedRequest == nil)
    }

    @Test("Defers the action and presents when unsubscribed")
    func requireDefersWhenUnsubscribed() {
        let service = makeService()
        var ran = false
        service.require(source: "newScript") { ran = true }
        #expect(!ran)
        #expect(service.presentedRequest?.source == "newScript")
    }

    /// Closing the paywall without buying must not run the gated action later by accident.
    @Test("Drops the deferred action when dismissed without a subscription")
    func dismissWithoutUnlockDropsAction() {
        let service = makeService()
        var ran = false
        service.require(source: "newScript") { ran = true }
        service.dismissPaywall()
        service.paywallDidDismiss()
        #expect(!ran)
    }

    /// A `require` whose sheet never showed (a sheet without `.paywallSheet()`) must not fire its
    /// action from an unrelated later paywall.
    @Test("Drops a deferred action when a new request replaces it")
    func newRequestDropsStaleAction() {
        let service = makeService()
        var ran = false
        service.require(source: "newScript") { ran = true }
        service.present(source: "settings")
        service.handleSuccessfulPurchase()
        service.paywallDidDismiss()
        #expect(!ran)
    }

    @Test("Runs the deferred action once the purchase went through")
    func dismissAfterUnlockRunsAction() {
        let service = makeService()
        var ran = false
        service.require(source: "newScript") { ran = true }
        service.handleSuccessfulPurchase()
        service.paywallDidDismiss()
        #expect(ran)
    }

    @Test("Runs the action immediately when subscribed")
    func requireRunsImmediatelyWhenSubscribed() {
        let service = makeService()
        service.handleSuccessfulPurchase()
        var ran = false
        service.require(source: "newScript") { ran = true }
        #expect(ran)
        #expect(service.presentedRequest == nil)
    }

    @Test("Restores the cached subscription state on launch")
    func restoresCache() {
        let first = makeService()
        first.handleSuccessfulPurchase()
        let second = PaywallService(configuration: config)
        #expect(second.hasSubscription)
        UserDefaults.standard.removeObject(forKey: PaywallService.cacheKey)
    }
}
