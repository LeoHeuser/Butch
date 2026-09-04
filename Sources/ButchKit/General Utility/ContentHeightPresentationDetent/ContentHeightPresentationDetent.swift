//
//  ContentHeightPresentationDetent.swift
//  ButchKit
//
//  Created by Leo Heuser on 27.09.25.
//

import SwiftUI
import OSLog

public extension View {
    /// Sizes a sheet to the height of what it contains, instead of a fixed detent.
    ///
    /// Put it on the **content**, inside whatever navigation container the sheet uses:
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     NavigationStack {
    ///         VStack { … }
    ///             .useContentHeightPresentationDetent
    ///     }
    /// }
    /// ```
    ///
    /// Not on the `NavigationStack` itself. `presentationDetents` reaches the enclosing sheet from
    /// anywhere in the tree, the way `navigationTitle` and `toolbar` do, so the modifier does not
    /// need to sit at the root — and it must not, because a navigation stack, a `ScrollView` or a
    /// `VStack` holding a `Spacer` all grow to whatever the current detent offers. Measuring one of
    /// those returns the height that was just set, and the sheet stays at its starting height
    /// forever. A DEBUG build reports that as an Xcode runtime issue rather than leaving you to
    /// wonder why the sheet is a stub.
    ///
    /// Do not combine with another `presentationDetents`; this sets its own.
    var useContentHeightPresentationDetent: some View {
        modifier(ContentHeightPresentationDetentModifier())
    }
}

/// Turns a measured content height into a sheet height, and recognises a measurement that cannot
/// work.
///
/// A value of its own so both rules can be tested: the runtime issue below fires from inside a
/// `ViewModifier` on a sheet nobody can open from a test.
struct SheetContentHeight {
    /// Breathing room around the content, plus the allowance for chrome that sits outside the
    /// measured view: an inline navigation bar is roughly 44pt, the home indicator adds a little
    /// more. One value, because it is one gap to tune.
    let padding: CGFloat = 32

    /// Floor for the detent. A sheet shorter than this reads as a glitch rather than a sheet, and it
    /// is what the very first layout pass falls back to, before anything has been measured.
    let minimum: CGFloat = 100

    /// The sheet height for a given content measurement.
    func detent(for measured: CGFloat) -> CGFloat {
        max(measured + padding, minimum)
    }

    /// Whether a new measurement shows that the measured view fills the sheet rather than having a
    /// height of its own.
    ///
    /// No heuristic, it falls out of the arithmetic. A view with its own height measures the same
    /// however much room the sheet offers, so the detent stays exactly `padding` above it. Measuring
    /// the whole detent back means the view stretched into it, and the sheet can never grow past
    /// where it started.
    ///
    /// - Parameters:
    ///   - measured: The height just reported.
    ///   - previous: The last height reported, `0` before the first one. The very first pass is
    ///     exempt: nothing has been applied yet, so there is no detent to have filled.
    func indicatesStretchingContent(measured: CGFloat, previous: CGFloat) -> Bool {
        previous > 0 && measured >= detent(for: previous)
    }
}

/// Measures the sheet content and turns the result into a single height detent.
public struct ContentHeightPresentationDetentModifier: ViewModifier {
    @State private var measuredHeight: CGFloat = 0
    @State private var hasReportedStretchingContent = false

    private let sizing = SheetContentHeight()

    public init() {}

    private var contentHeight: CGFloat {
        sizing.detent(for: measuredHeight)
    }

    public func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size.height, initial: true) { _, newHeight in
                            reportStretchingContentIfNeeded(measured: newHeight)
                            measuredHeight = newHeight
                        }
                }
            }
            .presentationDetents([.height(contentHeight)])
            .fittedWhereTheSystemSizesSheets()
    }

    /// Reports the one way this modifier can be used wrong, once per instance: applied to a view
    /// that fills whatever it is offered rather than one with a height of its own. See
    /// ``SheetContentHeight/indicatesStretchingContent(measured:previous:)``.
    private func reportStretchingContentIfNeeded(measured: CGFloat) {
#if DEBUG
        guard !hasReportedStretchingContent,
              sizing.indicatesStretchingContent(measured: measured, previous: measuredHeight)
        else { return }
        hasReportedStretchingContent = true

        // Subsystem "com.apple.runtime-issues" is what turns an os_log fault into a purple runtime
        // issue in Xcode's issue navigator, which jumps to the call site. A print would scroll past
        // in the console, and an assertion would stop the app over a layout mistake.
        os_log(
            .fault,
            log: OSLog(subsystem: "com.apple.runtime-issues", category: "ButchKit"),
            """
            useContentHeightPresentationDetent is measuring a view that fills the sheet instead of \
            one with a height of its own, so the sheet is stuck at %{public}.0fpt. Move it off the \
            NavigationStack, ScrollView or Spacer-holding container and onto the content inside it.
            """,
            contentHeight
        )
#endif
    }
}

private extension View {
    /// The system's own content sizing, from iOS 18, for the presentations that have it.
    ///
    /// It does **not** replace the measured detent above, it covers what that one cannot reach.
    /// `presentationSizing` applies in the regular size class — iPad and Mac — where sheets are form
    /// sheets and detents are ignored. In the compact size class, an iPhone, it is the other way
    /// round: the detent is what sizes the sheet and this is ignored. The two never apply at once,
    /// which is why both are set unconditionally. Do not delete the detent path as dead code.
    ///
    /// Isolated into a `@ViewBuilder` extension because `presentationSizing` changes the view type
    /// and cannot sit behind a plain `if #available` inside the modifier's body.
    @ViewBuilder
    func fittedWhereTheSystemSizesSheets() -> some View {
        if #available(iOS 18, macOS 15, *) {
            presentationSizing(.fitted)
        } else {
            self
        }
    }
}

#Preview("Short content") {
    @Previewable @State var isPresented = true

    Button("Show sheet") { isPresented = true }
        .sheet(isPresented: $isPresented) {
            VStack(spacing: 12) {
                Text(verbatim: "Sheet title")
                    .font(.headline)
                Text(verbatim: "This sheet adjusts its height to fit the content.")
            }
            .useContentHeightPresentationDetent
        }
}

#Preview("Long content") {
    @Previewable @State var isPresented = true

    Button("Show sheet") { isPresented = true }
        .sheet(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: "Sheet title")
                    .font(.headline)
                ForEach(1..<8) { index in
                    Text(verbatim: "Item \(index)")
                }
            }
            .useContentHeightPresentationDetent
        }
}

#Preview("Inside a NavigationStack") {
    @Previewable @State var isPresented = true

    Button("Show sheet") { isPresented = true }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                VStack(spacing: 12) {
                    Text(verbatim: "The modifier sits on the content, not on the stack around it.")
                    Text(verbatim: "A navigation stack fills whatever it is offered.")
                }
                .padding(.horizontal)
                .useContentHeightPresentationDetent
                .navigationTitle(Text(verbatim: "Title"))
            }
        }
}
