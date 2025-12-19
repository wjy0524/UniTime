//
//  Friend.swift
//  Quad-2025-project
//
//  Unified friend system models for the entire app
//

import FirebaseFirestore
import Foundation

// MARK: - Friend Model

/// Represents a bidirectional friendship between two users
struct Friend: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var userId: String  // Current user's ID
    var friendId: String  // Friend's user ID
    var friendUsername: String  // Friend's display name
    var friendEmail: String?
    var friendProfileImage: String?
    var createdAt: Date
    var acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case friendId
        case friendUsername
        case friendEmail
        case friendProfileImage
        case createdAt
        case acceptedAt
    }
}

// NOTE: FriendRequest is defined in StudyTracker/StudyFriend.swift
// NOTE: UserMini is defined in Calendar/UserMini.swift
// NOTE: FriendSearchResult is defined in StudyTracker/StudyFriend.swift

// MARK: - Friend Profile (Minimal)

/// Lightweight friend info for displaying in lists
struct FriendProfile: Identifiable {
    let id: String  // friendId
    let username: String
    let email: String?
    let profileImageURL: String?
    let major: String?
    let year: String?
}
