//
//  ShadcnRadio.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct ShadcnRadio: View {
    @Binding var selection: String
    var value: String
    
    @Environment(\.colorScheme) var cs
    
    var body: some View {
        Button(action: { selection = value }) {
            HStack(spacing: 10) {
                
                ZStack {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: 1.6)
                        .frame(width: 20, height: 20)
                    
                    if selection == value {
                        Circle()
                            .fill(primaryColor)
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text(value)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
    
    var primaryColor: Color { .accentColor }
    
    var borderColor: Color {
        selection == value ? primaryColor : Color.secondary.opacity(0.4)
    }
}
