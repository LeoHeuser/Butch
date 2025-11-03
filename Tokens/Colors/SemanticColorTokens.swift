//
//  SemanticTokens.swift
//  Butch
//

import SwiftUI

public extension Color {
    
    static var textPrimary: Color {
        adaptiveColor(light: .blackAlpha100, dark: .whiteAlpha100)
    }
    
    static var textSecondary: Color {
        adaptiveColor(light: .blackAlpha070, dark: .whiteAlpha070)
    }
    
    static var borderLight: Color {
        adaptiveColor(light: .blackAlpha020, dark: .whiteAlpha020)
    }
    
    static var accentBackground: Color {
        .orangeAlpha020
    }
    
    static var accentPrimary: Color {
        .orangeAlpha100
    }
    
    // MARK: - Button Tokens
    
    static var buttonForegroundPrimary: Color {
        adaptiveColor(light: .blackAlpha090, dark: .whiteAlpha090)
    }
    
    static var buttonForegroundInverted: Color {
        adaptiveColor(light: .whiteAlpha090, dark: .blackAlpha090)
    }
}
