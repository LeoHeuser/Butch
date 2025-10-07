//
//  DynamicSheetHeightModifier.swift
//  Butch
//
//  Created by Leo Heuser on 27.09.25.
//

import SwiftUI

// A ViewModifier that automatically adjusts sheet height to match content size.
// Uses GeometryReader to measure content height and applies it to presentationDetents for perfectly sized sheets.
//
// Usage:
// .sheet(isPresented: $showSheet) {
//     FolderCreationView()
//         .useContentHeightPresentationDetent
// }
//
// Requirements:
// - iOS 17.0+, macOS 14.0+
// - Apply directly to sheet content
// - Do not combine with other presentationDetents
extension View {
    // Automatically adjusts sheet height to content size.
    var useContentHeightPresentationDetent: some View {
        modifier(ContentHeightPresentationDetentModifier())
    }
}

// Internal modifier that measures content height and updates presentation detents.
// Optimized for performance using background GeometryReader and onChange.
private struct ContentHeightPresentationDetentModifier: ViewModifier {
    // Current measured content height
    @State private var contentHeight: CGFloat = 100
    
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size.height, initial: true) { _, newHeight in
                            contentHeight = newHeight
                        }
                }
            }
            .presentationDetents([.height(contentHeight)])
    }
}
