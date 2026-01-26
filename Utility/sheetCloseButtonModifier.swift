//
//  SwiftUIView.swift
//  ButchSDK
//
//  Created by Leo Heuser on 25.01.26.
//

import SwiftUI

// TODO: Das hier noch fertig machen. Da gibt es noch keinen Modifikator für.

struct DismissSheetButton: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.dismissSheet", systemImage: "xmark") {
                        
                    }
                }
            }
    }
}

public extension View {
    var sheetDismissButton: some View {
        modifier(DismissSheetButton())
    }
}

#Preview {
    VStack {
        Text("Background")
    }
    .sheet(isPresented: .constant(true)) {
        Text("Foreground")
            .sheetDismissButton
    }
}
