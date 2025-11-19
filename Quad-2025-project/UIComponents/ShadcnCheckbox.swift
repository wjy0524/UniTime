//
//  ShadcnCheckbox.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct ShadcnCheckbox: View {
    @Binding var isOn: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(borderColor, lineWidth: 1.6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isOn ? primaryColor : backgroundColor)
                    )
                    .frame(width: 22, height: 22)
                
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Style
    var primaryColor: Color {
        Color.accentColor
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ?
            Color(UIColor.systemGray5) :
            Color(UIColor.systemGray6)
    }
    
    var borderColor: Color {
        isOn ? primaryColor : Color.secondary.opacity(0.4)
    }
}
