//
//  ButchDoubleActionButton.swift
//  ButchSDK
//
//  Created by Leo Heuser on 06.11.25.
//

import SwiftUI

/// A double-action button with a primary and secondary action.
public struct ButchDoubleActionButton: View {
    // MARK: - Parameters
    private let primaryIcon: String
    private let primaryText: LocalizedStringKey
    private let secondaryIcon: String
    private let primaryAction: () -> Void
    private let secondaryAction: () -> Void
    private let secondaryWidth: CGFloat
    
    // MARK: - Initializer
    
    /// Creates a double-action button with configurable width ratio.
    /// - Parameters:
    ///   - primaryIcon: SF Symbol name for the primary action button
    ///   - primaryText: Localized text for the primary action button
    ///   - secondaryIcon: SF Symbol name for the secondary action button
    ///   - secondaryWidth: Width of the secondary button in points (default: 81)
    ///   - primaryAction: Action to perform when primary button is tapped
    ///   - secondaryAction: Action to perform when secondary button is tapped
    public init(
        primaryIcon: String,
        primaryText: LocalizedStringKey,
        secondaryIcon: String,
        secondaryWidth: CGFloat = 81,
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) {
        self.primaryIcon = primaryIcon
        self.primaryText = primaryText
        self.secondaryIcon = secondaryIcon
        self.secondaryWidth = secondaryWidth
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    // MARK: - View
    public var body: some View {
        HStack(spacing: 0) {
            PrimaryButton(
                icon: primaryIcon,
                text: primaryText,
                width: secondaryWidth * 2.5,
                action: primaryAction
            )
            
            SecondaryButton(
                icon: secondaryIcon,
                width: secondaryWidth,
                action: secondaryAction
            )
        }
        .frame(height: 60)
    }
}

// MARK: - Private Views

private struct PrimaryButton: View {
    let icon: String
    let text: LocalizedStringKey
    let width: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                
                Text(text)
                    .lineLimit(1)
            }
            .font(.system(size: 16))
            .frame(width: width, height: 60)
        }
        .background(Color.black.opacity(0.9))
        .foregroundStyle(Color.white.opacity(0.9))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .strokeBorder(Color.black.opacity(0.9), lineWidth: 1)
        )
    }
}

private struct SecondaryButton: View {
    let icon: String
    let width: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: width, height: 60)
        }
        .foregroundStyle(Color.black.opacity(0.9))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
            .strokeBorder(Color.black.opacity(0.9), lineWidth: 1)
        )
    }
}


#Preview {
    ButchDoubleActionButton(
        primaryIcon: "doc.viewfinder",
        primaryText: "button.scanDocument",
        secondaryIcon: "plus",
        primaryAction: { print("Primary action") },
        secondaryAction: { print("Secondary action") }
    )
    .padding()
}
