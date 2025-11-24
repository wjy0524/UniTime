//
//  NotificationModel.swift
//  Quad-2025-project
//
//  Created on Notification Feature Implementation
//

import FirebaseFirestore
import Foundation

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case follow = "follow"
    case followAccepted = "follow_accepted"
    case timetableShareRequest = "timetable_share_request"
    case timetableShareAccepted = "timetable_share_accepted"
    case timetableShareDeclined = "timetable_share_declined"
    case postLike = "post_like"
    case postComment = "post_comment"
    case eventInvite = "event_invite"

    var icon: String {
        switch self {
        case .follow, .followAccepted:
            return "person.badge.plus"
        case .timetableShareRequest:
            return "calendar.badge.plus"
        case .timetableShareAccepted:
            return "checkmark.circle.fill"
        case .timetableShareDeclined:
            return "xmark.circle.fill"
        case .postLike:
            return "heart.fill"
        case .postComment:
            return "bubble.left.fill"
        case .eventInvite:
            return "calendar.badge.clock"
        }
    }

    var color: String {
        switch self {
        case .follow, .followAccepted:
            return "blue"
        case .timetableShareRequest, .timetableShareAccepted:
            return "green"
        case .timetableShareDeclined:
            return "red"
        case .postLike:
            return "red"
        case .postComment:
            return "purple"
        case .eventInvite:
            return "orange"
        }
    }
}

// MARK: - Notification Model
struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let type: NotificationType
    let fromUserId: String
    let fromUsername: String
    let fromUserProfileImage: String?
    let toUserId: String
    let message: String
    let timestamp: Date
    var isRead: Bool

    var timetableShareId: String?
    var postId: String?
    var eventId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case fromUserId
        case fromUsername
        case fromUserProfileImage
        case toUserId
        case message
        case timestamp
        case isRead
        case timetableShareId
        case postId
        case eventId
    }

    init(
        id: String? = nil,
        type: NotificationType,
        fromUserId: String,
        fromUsername: String,
        fromUserProfileImage: String? = nil,
        toUserId: String,
        message: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        timetableShareId: String? = nil,
        postId: String? = nil,
        eventId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.fromUserProfileImage = fromUserProfileImage
        self.toUserId = toUserId
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.timetableShareId = timetableShareId
        self.postId = postId
        self.eventId = eventId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        type = try container.decode(NotificationType.self, forKey: .type)
        fromUserId = try container.decode(String.self, forKey: .fromUserId)
        fromUsername = try container.decode(String.self, forKey: .fromUsername)
        fromUserProfileImage = try container.decodeIfPresent(
            String.self, forKey: .fromUserProfileImage)
        toUserId = try container.decode(String.self, forKey: .toUserId)
        message = try container.decode(String.self, forKey: .message)

        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }

        isRead = try container.decode(Bool.self, forKey: .isRead)
        timetableShareId = try container.decodeIfPresent(String.self, forKey: .timetableShareId)
        postId = try container.decodeIfPresent(String.self, forKey: .postId)
        eventId = try container.decodeIfPresent(String.self, forKey: .eventId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(fromUserId, forKey: .fromUserId)
        try container.encode(fromUsername, forKey: .fromUsername)
        try container.encodeIfPresent(fromUserProfileImage, forKey: .fromUserProfileImage)
        try container.encode(toUserId, forKey: .toUserId)
        try container.encode(message, forKey: .message)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(isRead, forKey: .isRead)
        try container.encodeIfPresent(timetableShareId, forKey: .timetableShareId)
        try container.encodeIfPresent(postId, forKey: .postId)
        try container.encodeIfPresent(eventId, forKey: .eventId)
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Timetable Share Request Model
struct TimetableShareRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let fromUserId: String
    let fromUsername: String
    let fromUserProfileImage: String?
    let toUserId: String
    let toUsername: String
    let timestamp: Date
    var status: ShareStatus
    let timetableCourses: [TimetableCourse]
    enum ShareStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId
        case fromUsername
        case fromUserProfileImage
        case toUserId
        case toUsername
        case timestamp
        case status
        case timetableCourses
    }

    init(
        id: String? = nil,
        fromUserId: String,
        fromUsername: String,
        fromUserProfileImage: String? = nil,
        toUserId: String,
        toUsername: String,
        timestamp: Date = Date(),
        status: ShareStatus = .pending,
        timetableCourses: [TimetableCourse]
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.fromUserProfileImage = fromUserProfileImage
        self.toUserId = toUserId
        self.toUsername = toUsername
        self.timestamp = timestamp
        self.status = status
        self.timetableCourses = timetableCourses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        fromUserId = try container.decode(String.self, forKey: .fromUserId)
        fromUsername = try container.decode(String.self, forKey: .fromUsername)
        fromUserProfileImage = try container.decodeIfPresent(
            String.self, forKey: .fromUserProfileImage)
        toUserId = try container.decode(String.self, forKey: .toUserId)
        toUsername = try container.decode(String.self, forKey: .toUsername)

        // Handle Firestore Timestamp
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }

        status = try container.decode(ShareStatus.self, forKey: .status)
        timetableCourses = try container.decode([TimetableCourse].self, forKey: .timetableCourses)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(fromUserId, forKey: .fromUserId)
        try container.encode(fromUsername, forKey: .fromUsername)
        try container.encodeIfPresent(fromUserProfileImage, forKey: .fromUserProfileImage)
        try container.encode(toUserId, forKey: .toUserId)
        try container.encode(toUsername, forKey: .toUsername)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(status, forKey: .status)
        try container.encode(timetableCourses, forKey: .timetableCourses)
    }
}
