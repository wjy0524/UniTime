//
//  ChatModels.swift
//  Quad-2025-project
//
//  Chat models for marketplace messaging
//

import FirebaseFirestore
import Foundation

// MARK: - Chat Conversation

struct ChatConversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String]  // Array of user IDs
    var participantNames: [String: String]  // userId: username mapping
    var participantImages: [String: String]  // userId: profileImageURL mapping
    var itemId: String  // Marketplace item ID
    var itemTitle: String
    var itemPrice: Double
    var itemImageURL: String?
    var lastMessage: String
    var lastMessageTimestamp: Date
    var lastMessageSenderId: String
    var unreadCount: [String: Int]  // userId: unreadCount mapping
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case participantNames
        case participantImages
        case itemId
        case itemTitle
        case itemPrice
        case itemImageURL
        case lastMessage
        case lastMessageTimestamp
        case lastMessageSenderId
        case unreadCount
        case createdAt
    }

    // Get other user's ID
    func otherUserId(currentUserId: String) -> String? {
        participants.first { $0 != currentUserId }
    }

    // Get other user's name
    func otherUserName(currentUserId: String) -> String? {
        if let otherUserId = otherUserId(currentUserId: currentUserId) {
            return participantNames[otherUserId]
        }
        return nil
    }

    // Get other user's profile image
    func otherUserImage(currentUserId: String) -> String? {
        if let otherUserId = otherUserId(currentUserId: currentUserId) {
            return participantImages[otherUserId]
        }
        return nil
    }

    // Get unread count for current user
    func unreadCountForUser(_ userId: String) -> Int {
        unreadCount[userId] ?? 0
    }
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var senderName: String
    var senderImage: String?
    var text: String
    var timestamp: Date
    var isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId
        case senderId
        case senderName
        case senderImage
        case text
        case timestamp
        case isRead
    }

    // Check if message is from current user
    func isFromCurrentUser(currentUserId: String) -> Bool {
        senderId == currentUserId
    }

    // Format timestamp
    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }

        return formatter.string(from: timestamp)
    }
}

// MARK: - Chat Preview (for list view)

struct ChatPreview: Identifiable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let otherUserImage: String?
    let itemTitle: String
    let itemImageURL: String?
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    let isLastMessageFromMe: Bool

    var formattedLastMessageTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastMessageTime, relativeTo: Date())
    }
}
