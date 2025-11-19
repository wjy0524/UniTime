//
//  ShadcnCarousel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct ShadcnCarousel<Content: View>: View {
    let items: Int
    let spacing: CGFloat
    let content: (Int) -> Content
    
    @State private var currentIndex: Int = 0
    
    init(items: Int,
         spacing: CGFloat = 16,
         @ViewBuilder content: @escaping (Int) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                TabView(selection: $currentIndex) {
                    ForEach(0..<items, id: \.self) { index in
                        content(index)
                            .frame(width: geo.size.width)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // hide default dots
                .animation(.easeInOut, value: currentIndex)
                
                // LEFT BUTTON
                Button(action: scrollPrev) {
                    circleButton(icon: "chevron.left")
                }
                .disabled(currentIndex == 0)
                .position(
                    x: 24,
                    y: geo.size.height / 2
                )
                
                // RIGHT BUTTON
                Button(action: scrollNext) {
                    circleButton(icon: "chevron.right")
                }
                .disabled(currentIndex == items - 1)
                .position(
                    x: geo.size.width - 24,
                    y: geo.size.height / 2
                )
            }
        }
        .frame(height: 220)
    }
}

// MARK: - Scroll Functions
extension ShadcnCarousel {
    func scrollPrev() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    func scrollNext() {
        if currentIndex < items - 1 {
            currentIndex += 1
        }
    }
}

// MARK: - UI Helpers
extension ShadcnCarousel {
    func circleButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)
            .frame(width: 36, height: 36)
            .background(Color(.systemBackground).opacity(0.9))
            .clipShape(Circle())
            .shadow(radius: 2)
    }
}
