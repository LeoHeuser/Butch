import CoreGraphics
import Testing
@testable import ButchKit

@Suite("SheetContentHeight")
struct SheetContentHeightTests {
    private let sizing = SheetContentHeight()

    @Test("Adds the chrome allowance to what was measured")
    func detentAddsPadding() {
        #expect(sizing.detent(for: 200) == 232)
        #expect(sizing.detent(for: 400) == 432)
    }

    @Test("Never falls below the minimum, however short the content")
    func detentHasAFloor() {
        #expect(sizing.detent(for: 0) == 100)
        #expect(sizing.detent(for: 10) == 100)
        // The floor stops applying once the content plus padding clears it.
        #expect(sizing.detent(for: 68) == 100)
        #expect(sizing.detent(for: 69) == 101)
    }

    /// The healthy case: a view with a height of its own reports the same number whatever the sheet
    /// offers, so the detent stays exactly one padding above it and nothing is ever reported.
    @Test("Stays quiet while the content keeps its own height")
    func quietForContentWithItsOwnHeight() {
        #expect(!sizing.indicatesStretchingContent(measured: 200, previous: 200))
        #expect(!sizing.indicatesStretchingContent(measured: 231, previous: 200))
    }

    /// Content that grows for a real reason, a longer string or a larger Dynamic Type size, must not
    /// trip the warning either — as long as it does not grow all the way into the detent.
    @Test("Stays quiet when the content legitimately grows")
    func quietWhenContentGrows() {
        #expect(!sizing.indicatesStretchingContent(measured: 220, previous: 200))
    }

    /// The failure this exists for: the measured view filled the detent that was just applied, so
    /// every further pass would only hand the same number back.
    @Test("Reports content that filled the detent it was given")
    func reportsStretchingContent() {
        #expect(sizing.indicatesStretchingContent(measured: 232, previous: 200))
        #expect(sizing.indicatesStretchingContent(measured: 300, previous: 200))
    }

    /// The mistake as it actually unfolds: a NavigationStack at the root reports back whatever
    /// detent was applied last, pass after pass. The first pass is exempt, so this has to be caught
    /// on the second — before the sheet has settled into a size the developer would have to explain
    /// to themselves.
    @Test("Reports a root that only ever hands the applied detent back")
    func reportsRootFollowingTheDetent() {
        var previous: CGFloat = 0
        var measured = sizing.detent(for: previous)
        #expect(!sizing.indicatesStretchingContent(measured: measured, previous: previous))

        previous = measured
        measured = sizing.detent(for: previous)
        #expect(sizing.indicatesStretchingContent(measured: measured, previous: previous))
    }

    /// Before anything has been applied there is no detent that could have been filled, and a tall
    /// first measurement is just a tall sheet.
    @Test("Says nothing about the very first measurement")
    func firstMeasurementIsExempt() {
        #expect(!sizing.indicatesStretchingContent(measured: 400, previous: 0))
    }
}
