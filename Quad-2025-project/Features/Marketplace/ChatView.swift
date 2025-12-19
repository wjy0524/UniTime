//
//  ChatView.swift
//  Quad-2025-project
//
//  Chat view for marketplace item conversations
//

import FirebaseAuth
import Kingfisher
import SwiftUI

struct ChatView: View {
    let conversation: ChatConversation
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isSending = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Item Header
                itemHeader

                Divider()

                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatViewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.isFromCurrentUser(
                                        currentUserId: currentUserId),
                                    colorScheme: colorScheme
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatViewModel.messages.count) { _ in
                        if let lastMessage = chatViewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Message Input
                messageInputBar
            }
            .navigationTitle(
                conversation.otherUserName(currentUserId: currentUserId) ?? "Chat"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
            .onAppear {
                if let conversationId = conversation.id {
                    chatViewModel.startListeningToMessages(conversationId: conversationId)
                }
            }
            .onDisappear {
                chatViewModel.stopListeningToMessages()
            }
        }
    }

    // MARK: - Item Header

    var itemHeader: some View {
        HStack(spacing: 12) {
            // Item Image
            if let imageURL = conversation.itemImageURL,
                !imageURL.isEmpty,
                let url = URL(string: imageURL)
            {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.itemTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text("$\(String(format: "%.2f", conversation.itemPrice))")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1.0))
    }

    // MARK: - Message Input Bar

    var messageInputBar: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($isTextFieldFocused)
                .lineLimit(1...4)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .gray : .orange
                    )
            }
            .disabled(
                messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Send Message

    func sendMessage() {
        guard let conversationId = conversation.id else { return }
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isSending = true
        let text = messageText

        Task {
            do {
                try await chatViewModel.sendMessage(
                    conversationId: conversationId,
                    text: text
                )

                await MainActor.run {
                    messageText = ""
                    isSending = false
                }
            } catch {
                print("❌ Error sending message: \(error)")
                await MainActor.run {
                    isSending = false
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    var colorScheme: ColorScheme

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        isFromCurrentUser
                            ? Color.orange
                            : Color(.systemGray5).opacity(colorScheme == .dark ? 0.5 : 1.0)
                    )
                    .cornerRadius(18)

                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    ChatView(
        conversation: ChatConversation(
            participants: ["user1", "user2"],
            participantNames: ["user1": "John", "user2": "Jane"],
            participantImages: [:],
            itemId: "item1",
            itemTitle: "Test Item",
            itemPrice: 50.0,
            itemImageURL: nil,
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderId: "user1",
            unreadCount: ["user1": 0, "user2": 1],
            createdAt: Date()
        ),
        chatViewModel: ChatViewModel()
    )
}
