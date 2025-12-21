//
//  FloatingAIChatButton.swift
//  Quad-2025-project
//
//  Created by AI Assistant
//

import SwiftUI

struct FloatingAIChatButton: View {
    @State private var showChat = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showChat = true
                }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showChat) {
            AIChatView()
        }
    }
}

#Preview {
    FloatingAIChatButton()
}
