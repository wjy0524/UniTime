//
//  ChatListView.swift
//  Quad-2025-project
//
//  View showing all marketplace chat conversations
//

import FirebaseAuth
import Kingfisher
import SwiftUI

struct ChatListView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConversation: ChatConversation?
    @State private var showingChat = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                if chatViewModel.isLoading {
                    ProgressView("Loading chats...")
                } else if chatViewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                chatViewModel.startListeningToConversations()
            }
            .sheet(isPresented: $showingChat) {
                if let conversation = selectedConversation {
                    ChatView(
                        conversation: conversation,
                        chatViewModel: chatViewModel
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Messages Yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Start a conversation by contacting a seller")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Conversations List

    var conversationsList: some View {
        List {
            ForEach(chatViewModel.conversations) { conversation in
                Button {
                    selectedConversation = conversation
                    showingChat = true
                } label: {
                    ConversationRow(
                        conversation: conversation,
                        currentUserId: Auth.auth().currentUser?.uid ?? ""
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteConversation(conversation)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Delete Conversation

    func deleteConversation(_ conversation: ChatConversation) {
        Task {
            do {
                if let conversationId = conversation.id {
                    try await chatViewModel.deleteConversation(conversationId: conversationId)
                }
            } catch {
                print("❌ Error deleting conversation: \(error)")
            }
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: ChatConversation
    let currentUserId: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageURL = conversation.otherUserImage(currentUserId: currentUserId),
                !imageURL.isEmpty,
                let url = URL(string: imageURL)
            {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                // Other user name
                Text(conversation.otherUserName(currentUserId: currentUserId) ?? "Unknown")
                    .font(.headline)
                    .lineLimit(1)

                // Item title
                Text(conversation.itemTitle)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .lineLimit(1)

                // Last message
                HStack(spacing: 4) {
                    if conversation.lastMessageSenderId == currentUserId {
                        Text("You:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // Time
                Text(formatTime(conversation.lastMessageTimestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Unread badge
                if conversation.unreadCountForUser(currentUserId) > 0 {
                    Text("\(conversation.unreadCountForUser(currentUserId))")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Circle().fill(Color.orange))
                }
            }
        }
        .padding(.vertical, 4)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChatListView()
}
