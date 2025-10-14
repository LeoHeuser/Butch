//
//  ButchTextField.swift
//  Butch
//
//  Created by Leo Heuser on 25.09.25.
//

import SwiftUI

public struct ButchTextField: View {
    // MARK: - Parameters
    @Binding private var text: String
    @FocusState private var isFocused: Bool
    
    private let placeholder: LocalizedStringKey
    private let leadingIcon: String?
    
    @Environment(\.isEnabled) private var isEnabled
    
    public init(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        leadingIcon: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.leadingIcon = leadingIcon
    }
    
    // MARK: - Component
    public var body: some View {
        HStack(spacing: 8) {
            if let icon = leadingIcon {
                LeadingIcon(systemName: icon)
            }
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .foregroundStyle(.primary)
            
            ClearButton(action: clearText)
                .scaleEffect(text.isEmpty ? 0.6 : 1.0)
                .opacity(text.isEmpty ? 0 : 1)
                .animation(.bouncy(duration: 0.3), value: text.isEmpty)
        }
        .padding(.leading, .spacing16)
        .padding(.trailing, .spacing8)
        .padding(.vertical, .spacing8)
        .frame(minHeight: 54)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.4)
        .allowsHitTesting(isEnabled)
        .contentShape(Capsule())
        .onTapGesture {
            if isEnabled {
                isFocused = true
            }
        }
    }
    
    private func clearText() {
        text = ""
    }
}

// MARK: - Component Parts
extension ButchTextField {
    /// Leading icon displayed at the start of the text field.
    private struct LeadingIcon: View {
        let systemName: String
        
        var body: some View {
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
        }
    }
    
    /// Clear button to empty the text field.
    private struct ClearButton: View {
        let action: () -> Void
        @State private var triggerFeedback = false
        
        var body: some View {
            Button(action: {
                triggerFeedback.toggle()
                action()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: triggerFeedback)
        }
    }
}

// MARK: - Preview
#Preview("Standard") {
    @Previewable @State var text = ""
    
    ButchTextField("textfield.placeholder", text: $text)
        .padding()
}

#Preview("With Icon") {
    @Previewable @State var text = ""
    
    ButchTextField(
        "textfield.placeholder",
        text: $text,
        leadingIcon: "camera"
    )
    .padding()
}

#Preview("Disabled") {
    @Previewable @State var text = "Some text"
    
    ButchTextField(
        "textfield.placeholder",
        text: $text
    )
    .disabled(true)
    .padding()
}

#Preview("Disabled With Icon") {
    @Previewable @State var text = "Some text"
    
    ButchTextField(
        "textfield.placeholder",
        text: $text,
        leadingIcon: "camera"
    )
    .disabled(true)
    .padding()
}
