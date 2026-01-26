//
//  sheetCloseButtonModifier.swift
//  ButchSDK
//
//  Created by Leo Heuser on 25.01.26.
//

import SwiftUI

struct DismissSheetButton: ViewModifier {
    @Environment(\.dismiss) var dismiss
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.dismissSheet", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
    }
}

public extension View {
    func sheetDismissButton() -> some View {
        modifier(DismissSheetButton())
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    
    VStack {
        Button("Show Sheet") {
            isPresented.toggle()
        }
    }
    .sheet(isPresented: $isPresented) {
        NavigationStack {
            Text("Foreground")
                .sheetDismissButton()
        }
    }
}
