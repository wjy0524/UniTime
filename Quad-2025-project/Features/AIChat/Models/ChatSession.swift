//
//  ChatSession.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 12/31/25.
//

import Foundation

struct ChatSession: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [AIChatMessage]
    var isPinned: Bool   // ⭐ 추가

    init(
        id: UUID = UUID(),
        title: String,
        messages: [AIChatMessage],
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.isPinned = isPinned
    }
}
