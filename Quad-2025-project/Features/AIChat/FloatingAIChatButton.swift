//
//  FloatingAIChatButton.swift
//  Quad-2025-project
//

import SwiftUI

struct FloatingAIChatButton: View {
    @State private var showChat = false
    @State private var isHidden = false

    var body: some View {
        Group {
            if !isHidden {
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
                    AIChatContainerView()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .hideGlobalChat)) { _ in
            isHidden = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showGlobalChat)) { _ in
            isHidden = false
        }
    }
}

// Add this extension
extension Notification.Name {
    static let hideGlobalChat = Notification.Name("hideGlobalChat")
    static let showGlobalChat = Notification.Name("showGlobalChat")
}

#Preview {
    FloatingAIChatButton()
}
