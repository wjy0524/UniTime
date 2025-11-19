//
//  ShadcnTextField.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct ShadcnTextField: View {
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var icon: Image? = nil
    var disabled: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            
            // Left icon (optional)
            if let icon = icon {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.leading, 4)
            }
            
            // TextField / SecureField
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .textInputStyle
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .textInputStyle
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(inputBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
        .cornerRadius(8)
        .opacity(disabled ? 0.5 : 1)
        .disabled(disabled)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}


// MARK: - Style helpers
extension ShadcnTextField {
    
    private var inputBackground: Color {
        colorScheme == .light
        ? Color(UIColor.systemBackground)
        : Color(UIColor.secondarySystemBackground)
    }
    
    private var borderColor: Color {
        if isFocused {
            return Color.blue.opacity(0.8)     // shadcn focus ring color
        }
        return Color.gray.opacity(0.25)
    }
}


// MARK: - Text Modifier (to match shadcn style)
extension View {
    var textInputStyle: some View {
        self.font(.system(size: 15))
            .foregroundColor(.primary)
            .padding(.vertical, 4)
    }
}
