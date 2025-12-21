//
//  AIChatView.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/20/25.
//

import SwiftUI

struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AIChatViewModel()
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                Text("Thinking...")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                HStack {
                    TextField("Ask anything...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("AI Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    func sendMessage() {
        let text = messageText
        messageText = ""
        Task {
            await viewModel.sendMessage(text)
        }
    }
}
