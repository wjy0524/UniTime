//
//  AIChatViewModel.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/20/25.
//

import SwiftUI

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [AIChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let chatService = ChatService()
    
    func sendMessage(_ text: String) async {
        let userMessage = AIChatMessage(text: text, isFromUser: true)
        messages.append(userMessage)
        
        isLoading = true
        errorMessage = nil
        
        do {
            let reply = try await chatService.sendMessage(text)
            let aiMessage = AIChatMessage(text: reply, isFromUser: false)
            messages.append(aiMessage)
        } catch {
            errorMessage = "Failed to get response: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
