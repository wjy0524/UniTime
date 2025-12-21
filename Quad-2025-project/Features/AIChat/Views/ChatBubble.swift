//
//  ChatBubble.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/20/25.
//

import SwiftUI

struct ChatBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            Text(message.text)
                .padding(12)
                .background(message.isFromUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isFromUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isFromUser { Spacer() }
        }
    }
}
