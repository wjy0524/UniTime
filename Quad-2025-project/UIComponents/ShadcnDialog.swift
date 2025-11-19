//
//  ShadcnDialog.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

// MARK: - Shadcn Dialog Container
struct ShadcnDialog<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background overlay
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
                
                // Dialog content box
                VStack(spacing: 0) {
                    content
                }
                .background(
                    colorScheme == .dark ?
                    Color(UIColor.secondarySystemBackground) :
                    Color.white
                )
                .cornerRadius(20)
                .padding(.horizontal, 24)
                .transition(
                    .scale(scale: 0.92)
                    .combined(with: .opacity)
                    .animation(.easeOut(duration: 0.22))
                )
            }
        }
        .animation(.easeOut, value: isPresented)
    }
}



// MARK: - Title
struct ShadcnDialogTitle: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold))
            .multilineTextAlignment(.center)
            .padding(.top, 20)
            .padding(.horizontal, 16)
    }
}



// MARK: - Description
struct ShadcnDialogDescription: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, 4)
    }
}



// MARK: - Footer buttons
struct ShadcnDialogFooter<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            content
        }
        .padding(20)
    }
}



// MARK: - View Modifier (easy usage)
extension View {
    func shadcnDialog<DialogContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> DialogContent
    ) -> some View {
        self.overlay(
            ShadcnDialog(isPresented: isPresented) {
                content()
            }
        )
    }
}
