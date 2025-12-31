//
//  AIChatContainerView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 12/31/25.
//

import SwiftUI

struct AIChatContainerView: View {
    @StateObject private var chatStore = ChatStore()
    @State private var isDrawerOpen = false

    var body: some View {
        ZStack(alignment: .leading) {

            // ✅ Main Chat
            AIChatView(
                chatStore: chatStore,
                onMenuTap: {
                    withAnimation {
                        isDrawerOpen.toggle()
                    }
                }
            )
            .disabled(isDrawerOpen)
            .overlay(
                // Dim background
                Group {
                    if isDrawerOpen {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    isDrawerOpen = false
                                }
                            }
                    }
                }
            )

            // ✅ Left Drawer
            if isDrawerOpen {
                AIChatListView(
                    chatStore: chatStore,
                    onClose: {
                        withAnimation {
                            isDrawerOpen = false
                        }
                    }
                )
                    .frame(width: 300)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
    }
}
