//
//  ShadcnButton.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

// MARK: - Variant & Size

enum ShadcnButtonVariant {
    case `default`
    case destructive
    case outline
    case secondary
    case ghost
    case link
}

enum ShadcnButtonSize {
    case defaultSize
    case sm
    case lg
    case icon
}

// MARK: - ShadcnButton Style

struct ShadcnButton: View {
    var title: String
    var icon: Image? = nil
    var variant: ShadcnButtonVariant = .default
    var size: ShadcnButtonSize = .defaultSize
    var action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(height: iconSize)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(buttonPadding)
            .frame(height: buttonHeight)
            .frame(maxWidth: size == .icon ? 40 : .infinity, alignment: .center)
            .background(buttonBackground)
            .foregroundColor(buttonForeground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(8)
            .opacity(isDisabled ? 0.5 : 1)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Style Computed Properties
extension ShadcnButton {
    
    private var isDisabled: Bool { false }
    
    private var buttonHeight: CGFloat {
        switch size {
        case .sm: return 32
        case .defaultSize: return 36
        case .lg: return 44
        case .icon: return 40
        }
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .sm: return 14
        case .defaultSize: return 16
        case .lg: return 18
        case .icon: return 20
        }
    }
    
    private var buttonPadding: EdgeInsets {
        switch size {
        case .sm: return EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        case .defaultSize: return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        case .lg: return EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        case .icon: return EdgeInsets()
        }
    }
    
    private var buttonBackground: Color {
        switch variant {
        case .default:
            return Color("Primary")
        case .destructive:
            return Color.red.opacity(0.85)
        case .outline, .ghost, .link:
            return Color.clear
        case .secondary:
            return Color("Secondary")
        }
    }
    
    private var buttonForeground: Color {
        switch variant {
        case .default, .secondary:
            return Color.white
        case .destructive:
            return Color.white
        case .outline:
            return Color.primary
        case .ghost:
            return Color.primary
        case .link:
            return Color("Primary")
        }
    }
    
    private var borderWidth: CGFloat {
        switch variant {
        case .outline: return 1
        default: return 0
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .outline:
            return Color.primary.opacity(0.25)
        default:
            return .clear
        }
    }
}
