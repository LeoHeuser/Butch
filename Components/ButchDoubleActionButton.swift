//
//  ButchDoubleActionButton.swift
//  ButchSDK
//
//  Created by Leo Heuser on 06.11.25.
//

import SwiftUI

/// A double-action button combining primary and secondary actions.
public struct ButchDoubleActionButton: View {
    // MARK: - Properties
    private let primaryIcon: String
    private let primaryText: LocalizedStringKey
    private let secondaryIcon: String
    private let primaryAction: () -> Void
    private let secondaryAction: () -> Void
    private let secondaryWidth: CGFloat
    
    // MARK: - Initializer
    
    /// Creates a double-action button.
    /// - Parameters:
    ///   - primaryIcon: SF Symbol for primary button
    ///   - primaryText: Localized text for primary button
    ///   - secondaryIcon: SF Symbol for secondary button
    ///   - secondaryWidth: Width of secondary button in points (default: 81)
    ///   - primaryAction: Primary button action
    ///   - secondaryAction: Secondary button action
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
            Button(action: primaryAction) {
                HStack(spacing: 4) {
                    Image(systemName: primaryIcon)
                    Text(primaryText)
                        .lineLimit(1)
                }
                .font(.system(size: 16))
                .frame(width: secondaryWidth * 2.5, height: 60)
            }
            .buttonStyle(PrimaryDoubleButtonStyle())
            
            Button(action: secondaryAction) {
                Image(systemName: secondaryIcon)
                    .font(.system(size: 16))
                    .frame(width: secondaryWidth, height: 60)
            }
            .buttonStyle(SecondaryDoubleButtonStyle())
        }
        .frame(height: 60)
    }
}

// MARK: - Button Styles

private struct PrimaryDoubleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.buttonForegroundPrimary)
            .foregroundStyle(Color.buttonForegroundInverted)
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
                .strokeBorder(Color.buttonForegroundPrimary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

private struct SecondaryDoubleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.buttonForegroundPrimary)
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
                .strokeBorder(Color.buttonForegroundPrimary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
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
