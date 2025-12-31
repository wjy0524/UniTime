//
//  ChatMessage.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/20/25.
//

import Foundation

struct AIChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date

    init(
        id: UUID = UUID(),
        text: String,
        isFromUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}
