//
//  StudyFriend.swift
//  Quad-2025-project
//
//  Models for study friends, friend requests, and live study tracking
//

import FirebaseFirestore
import Foundation

// MARK: - Study Friend Model

struct StudyFriend: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String  // Current user's ID
    var friendId: String  // Friend's user ID
    var friendUsername: String  // Friend's display name
    var friendEmail: String?
    var status: FriendStatus
    var createdAt: Date
    var acceptedAt: Date?

    enum FriendStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case friendId
        case friendUsername
        case friendEmail
        case status
        case createdAt
        case acceptedAt
    }
}

// MARK: - Friend Request Model

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var fromUserId: String  // Who sent the request
    var toUserId: String  // Who receives the request
    var fromUsername: String
    var toUsername: String
    var fromProfileImage: String?  // Sender's profile image
    var toProfileImage: String?  // Receiver's profile image
    var status: RequestStatus
    var createdAt: Date
    var respondedAt: Date?
    var message: String?  // Optional message with request

    enum RequestStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case cancelled = "cancelled"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId
        case toUserId
        case fromUsername
        case toUsername
        case fromProfileImage
        case toProfileImage
        case status
        case createdAt
        case respondedAt
        case message
    }
}

// MARK: - Friend Study Status (Real-time)

struct FriendStudyStatus: Identifiable {
    let id: String  // friendId
    let userId: String
    let username: String
    var isStudying: Bool
    var currentSessionId: String?
    var sessionStartTime: Date?
    var elapsedTime: TimeInterval  // Current session time
    var todayTotalTime: TimeInterval  // Total study time today
    var weekTotalTime: TimeInterval  // Total study time this week
    var lastUpdated: Date

    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedTodayTime: String {
        let hours = Int(todayTotalTime) / 3600
        let minutes = Int(todayTotalTime) % 3600 / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "0m"
        }
    }

    var formattedWeekTime: String {
        let hours = Int(weekTotalTime) / 3600
        let minutes = Int(weekTotalTime) % 3600 / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "0m"
        }
    }
}

// MARK: - Friend Search Result

struct FriendSearchResult: Identifiable {
    let id: String  // userId
    let username: String
    let email: String?
    let profileImageURL: String?
    let major: String?
    let year: String?
    var isFriend: Bool
    var hasPendingRequest: Bool
    var requestSentByMe: Bool
}

// MARK: - Study Leaderboard Entry

struct StudyLeaderboardEntry: Identifiable {
    let id: String  // userId
    let username: String
    var weeklyStudyTime: TimeInterval
    var rank: Int
    var isCurrentUser: Bool

    var formattedTime: String {
        let hours = Int(weeklyStudyTime) / 3600
        let minutes = Int(weeklyStudyTime) % 3600 / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "0m"
        }
    }
}
