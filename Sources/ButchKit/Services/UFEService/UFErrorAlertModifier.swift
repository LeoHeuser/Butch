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
 
 */

import SwiftUI

struct UserFacingErrorsModifier: ViewModifier {
    @Environment(UFEService.self) private var ufes
    
    func body(content: Content) -> some View {
        content.alert(
            ufes.currentError?.title ?? LocalizedStringKey(""),
            isPresented: Binding(
                get: { ufes.currentError != nil },
                set: { isPresented in
                    if !isPresented { ufes.dismiss() }
                }
            ),
            presenting: ufes.currentError,
            actions: { _ in
                Button("button.ok", role: .cancel) { ufes.dismiss() }
            },
            message: { error in
                Text(error.message)
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
