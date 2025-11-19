//
//  ShadcnDialog.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

// MARK: - Card Container
struct ShadcnCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.12)
        : Color.black.opacity(0.1)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(UIColor.secondarySystemBackground)
        : Color.white
    }
}



// MARK: - Card Header
struct ShadcnCardHeader<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}



// MARK: - Card Title
struct ShadcnCardTitle: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.primary)
    }
}



// MARK: - Card Description
struct ShadcnCardDescription: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
    }
}



// MARK: - Card Content
struct ShadcnCardContent<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}



// MARK: - Card Footer
struct ShadcnCardFooter<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .padding(20)
    }
}
