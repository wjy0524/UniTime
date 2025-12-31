//
//  AIChatViewModel.swift
//  Quad-2025-project
//

import SwiftUI

@MainActor
class AIChatViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let chatService = ChatService()
    private let chatStore: ChatStore

    init(chatStore: ChatStore) {
        self.chatStore = chatStore
    }

    // 🔹 View에서 읽기만 하는 메시지
    var messages: [AIChatMessage] {
        chatStore.currentMessages
    }

    func sendMessage(_ text: String) async {

        // ⭐ 여기서 세션 확정 생성
        chatStore.createNewSessionIfNeeded()

        let userMessage = AIChatMessage(text: text, isFromUser: true)

        var updated = chatStore.currentMessages
        updated.append(userMessage)
        chatStore.currentMessages = updated

        chatStore.updateTitleIfNeeded(using: text)

        isLoading = true
        errorMessage = nil

        do {
            let reply = try await chatService.sendMessage(text)
            let aiMessage = AIChatMessage(text: reply, isFromUser: false)

            updated.append(aiMessage)
            chatStore.currentMessages = updated
        } catch {
            errorMessage = "Failed to get response"
        }

        isLoading = false
    }

}
