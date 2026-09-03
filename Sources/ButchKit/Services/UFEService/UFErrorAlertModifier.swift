//
//  UFErrorAlertModifier.swift
//  ButchKit
//
//  Created by Leo Heuser on 21.05.26.
//

/**
 
 # UFErrorAlertModifier
 Attaches a native alert to a view that presents whatever `UFError` the `UFEService` from the environment is currently holding.
 
 ## Primary entry point — root level
 Apply once at the highest possible point in your app (the root view inside `WindowGroup`). This both injects the `UFEService` into the environment and attaches the alert. Because SwiftUI's `.alert` is presented at the window level, it floats above sheets, full-screen covers, navigation stacks and so on:
 ```swift
 RootView()
 .userFacingErrors(ufes)
 ```
 
 ## Reinforcement — optional, inside sheets / deep modal stacks
 Multi-window apps and very deeply nested modal stacks (a sheet inside a sheet inside a full-screen cover) can occasionally swallow a root-level alert. For those edge cases you can sprinkle the parameterless variant inside the affected sheet content. It reads the already-injected `UFEService` from the environment and only attaches an additional alert binding — no service injection happens:
 ```swift
 SheetContent()
 .userFacingErrors()
 ```
 Use the argumentless form only inside views that live below a view that already applied `.userFacingErrors(ufes)`, otherwise the environment lookup will trap at runtime.
 
 ## Localization
 The error's `title` and `message` are looked up in the app's `Errors.xcstrings`. The alert's OK
 button is not: a button is a button wherever it appears, so `button.ok` stays on the default
 table. See `StringTable`.
 
 */

import SwiftUI

struct UserFacingErrorsModifier: ViewModifier {
    @Environment(UFEService.self) private var ufes
    
    /// The title has to exist before there is an error to take it from: it sits outside the
    /// `presenting:` closure, unlike the message.
    ///
    /// Verbatim empty text rather than an empty key. An empty `LocalizedStringKey` is a real
    /// catalog lookup, and it would land in the app's catalog as a string to translate.
    private var title: Text {
        guard let error = ufes.currentError else { return Text(verbatim: "") }
        
        return Text(error: error.title)
    }
    
    func body(content: Content) -> some View {
        content.alert(
            title,
            isPresented: Binding(
                get: { ufes.currentError != nil },
                set: { isPresented in
                    if !isPresented { ufes.dismiss() }
                }
            ),
            presenting: ufes.currentError,
            actions: { _ in
                // A button, not an error, so it stays on the default table even though it is
                // the one thing in here the user reads after something went wrong.
                Button("button.ok", role: .cancel) { ufes.dismiss() }
            },
            message: { error in
                Text(error: error.message)
            }
        )
    }
}

public extension View {
    /// Root-level entry point. Injects `service` into the environment and attaches the alert.
    /// Apply once at the highest point of your app.
    func userFacingErrors(_ service: UFEService) -> some View {
        modifier(UserFacingErrorsModifier())
            .environment(service)
    }
    
    /// Reinforcement variant for deep modal stacks. Attaches an additional alert binding
    /// to the current view, reading the `UFEService` from the environment.
    /// Requires that a parent already applied `.userFacingErrors(_:)`.
    func userFacingErrors() -> some View {
        modifier(UserFacingErrorsModifier())
    }
}

#Preview {
    @Previewable @State var ufes = UFEService()
    
    Button("Throw Error") {
        ufes.info(title: "Info Title", message: "Some informational message.")
    }
    .userFacingErrors(ufes)
}
