//
//  ChatMessage.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/20/25.
//

import Foundation

struct AIChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp = Date()
}
