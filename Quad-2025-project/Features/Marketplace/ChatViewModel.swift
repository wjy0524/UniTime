//
//  ChatViewModel.swift
//  Quad-2025-project
//
//  ViewModel for managing marketplace chat conversations and messages
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [ChatConversation] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    deinit {
        conversationsListener?.remove()
        messagesListener?.remove()
    }

    // MARK: - Start Listening to Conversations

    func startListeningToConversations() {
        guard let userId = currentUserId else {
            print("❌ No user ID for listening to conversations")
            return
        }

        print("👂 Starting to listen for conversations...")

        conversationsListener = db.collection("chatConversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching conversations: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No conversations found")
                    return
                }

                let fetchedConversations = documents.compactMap { doc -> ChatConversation? in
                    try? doc.data(as: ChatConversation.self)
                }

                Task { @MainActor in
                    self.conversations = fetchedConversations
                    print("✅ Loaded \(fetchedConversations.count) conversations")
                }
            }
    }

    // MARK: - Start Listening to Messages in a Conversation

    func startListeningToMessages(conversationId: String) {
        print("👂 Starting to listen for messages in conversation: \(conversationId)")

        messagesListener?.remove()

        messagesListener = db.collection("chatConversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching messages: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No messages found")
                    return
                }

                let fetchedMessages = documents.compactMap { doc -> ChatMessage? in
                    try? doc.data(as: ChatMessage.self)
                }

                Task { @MainActor in
                    self.messages = fetchedMessages
                    print("✅ Loaded \(fetchedMessages.count) messages")

                    // Mark messages as read
                    self.markMessagesAsRead(conversationId: conversationId)
                }
            }
    }

    func stopListeningToMessages() {
        messagesListener?.remove()
        messages = []
    }

    // MARK: - Create or Get Conversation

    func getOrCreateConversation(
        withUserId otherUserId: String,
        otherUsername: String,
        otherUserImage: String?,
        forItem item: MarketplaceItem
    ) async throws -> String {
        guard let currentUserId = currentUserId else {
            throw NSError(
                domain: "Chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Check if conversation already exists
        let existingConversations = try await db.collection("chatConversations")
            .whereField("participants", arrayContains: currentUserId)
            .whereField("itemId", isEqualTo: item.id ?? "")
            .getDocuments()

        // Find conversation with both participants and this item
        if let existingConv = existingConversations.documents.first(where: { doc in
            let data = doc.data()
            let participants = data["participants"] as? [String] ?? []
            return participants.contains(otherUserId)
        }) {
            print("✅ Found existing conversation: \(existingConv.documentID)")
            return existingConv.documentID
        }

        // Create new conversation
        print("📝 Creating new conversation")

        // Get current user info
        let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let currentUserData = currentUserDoc.data(),
            let currentUsername = currentUserData["username"] as? String
        else {
            throw NSError(
                domain: "Chat", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not fetch user data"])
        }

        let currentUserImage = currentUserData["profileImageURL"] as? String

        var participantNames: [String: String] = [:]
        participantNames[currentUserId] = currentUsername
        participantNames[otherUserId] = otherUsername

        var participantImages: [String: String] = [:]
        if let currentUserImage = currentUserImage {
            participantImages[currentUserId] = currentUserImage
        }
        if let otherUserImage = otherUserImage {
            participantImages[otherUserId] = otherUserImage
        }

        var unreadCount: [String: Int] = [:]
        unreadCount[currentUserId] = 0
        unreadCount[otherUserId] = 0

        let conversation = ChatConversation(
            participants: [currentUserId, otherUserId],
            participantNames: participantNames,
            participantImages: participantImages,
            itemId: item.id ?? "",
            itemTitle: item.title,
            itemPrice: item.price,
            itemImageURL: item.imageURLs.first,
            lastMessage: "",
            lastMessageTimestamp: Date(),
            lastMessageSenderId: currentUserId,
            unreadCount: unreadCount,
            createdAt: Date()
        )

        let docRef = try db.collection("chatConversations").addDocument(from: conversation)
        print("✅ Created new conversation: \(docRef.documentID)")

        return docRef.documentID
    }

    // MARK: - Send Message

    func sendMessage(conversationId: String, text: String) async throws {
        guard let currentUserId = currentUserId else {
            throw NSError(
                domain: "Chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Get current user info
        let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let currentUserData = currentUserDoc.data(),
            let currentUsername = currentUserData["username"] as? String
        else {
            throw NSError(
                domain: "Chat", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not fetch user data"])
        }

        let currentUserImage = currentUserData["profileImageURL"] as? String

        let message = ChatMessage(
            conversationId: conversationId,
            senderId: currentUserId,
            senderName: currentUsername,
            senderImage: currentUserImage,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date(),
            isRead: false
        )

        // Add message to subcollection
        try db.collection("chatConversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(from: message)

        // Get conversation to update unread counts
        let conversationDoc = try await db.collection("chatConversations")
            .document(conversationId)
            .getDocument()

        guard let conversationData = conversationDoc.data(),
            let participants = conversationData["participants"] as? [String],
            var unreadCount = conversationData["unreadCount"] as? [String: Int]
        else {
            return
        }

        // Increment unread count for other user
        for participant in participants where participant != currentUserId {
            unreadCount[participant] = (unreadCount[participant] ?? 0) + 1
        }

        // Update conversation with last message and unread counts
        try await db.collection("chatConversations")
            .document(conversationId)
            .updateData([
                "lastMessage": text.trimmingCharacters(in: .whitespacesAndNewlines),
                "lastMessageTimestamp": Timestamp(date: Date()),
                "lastMessageSenderId": currentUserId,
                "unreadCount": unreadCount,
            ])

        // Send notification to other user
        for participant in participants where participant != currentUserId {
            await sendChatNotification(
                toUserId: participant,
                conversationId: conversationId,
                message: text.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        print("✅ Message sent")
    }

    // MARK: - Mark Messages as Read

    func markMessagesAsRead(conversationId: String) {
        guard let currentUserId = currentUserId else { return }

        Task {
            do {
                // Reset unread count for current user
                try await db.collection("chatConversations")
                    .document(conversationId)
                    .updateData([
                        "unreadCount.\(currentUserId)": 0
                    ])

                print("✅ Marked messages as read")
            } catch {
                print("❌ Error marking messages as read: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Delete Conversation

    func deleteConversation(conversationId: String) async throws {
        // Delete all messages in the conversation
        let messages = try await db.collection("chatConversations")
            .document(conversationId)
            .collection("messages")
            .getDocuments()

        for message in messages.documents {
            try await message.reference.delete()
        }

        // Delete the conversation
        try await db.collection("chatConversations")
            .document(conversationId)
            .delete()

        print("✅ Conversation deleted")
    }

    // MARK: - Get Total Unread Count

    func getTotalUnreadCount() -> Int {
        guard let currentUserId = currentUserId else { return 0 }

        return conversations.reduce(0) { total, conversation in
            total + conversation.unreadCountForUser(currentUserId)
        }
    }

    // MARK: - Send Chat Notification

    private func sendChatNotification(toUserId: String, conversationId: String, message: String)
        async
    {
        guard let currentUserId = currentUserId else { return }

        do {
            // Get current user info
            let currentUserDoc = try await db.collection("users").document(currentUserId)
                .getDocument()
            guard let currentUserData = currentUserDoc.data(),
                let currentUsername = currentUserData["username"] as? String
            else {
                return
            }

            let currentUserImage = currentUserData["profileImageURL"] as? String

            // Create notification
            let notificationData: [String: Any] = [
                "type": "chat_message",
                "fromUserId": currentUserId,
                "fromUsername": currentUsername,
                "fromUserProfileImage": currentUserImage ?? "",
                "toUserId": toUserId,
                "message": "\(currentUsername): \(message)",
                "timestamp": Timestamp(date: Date()),
                "isRead": false,
                "conversationId": conversationId,
            ]

            try await db.collection("notifications").addDocument(data: notificationData)
            print("✅ Chat notification sent")
        } catch {
            print("❌ Error sending chat notification: \(error)")
        }
    }
}
