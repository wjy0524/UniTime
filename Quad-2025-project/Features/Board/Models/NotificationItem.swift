//
//  NotificationItem.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import Foundation
import FirebaseFirestore

struct NotificationItem: Identifiable, Codable {
    @DocumentID var id: String?

    var type: String          // "like_post", "comment_post", "reply_comment"
    var senderId: String
    var postId: String?
    var commentId: String?
    var message: String
    var timestamp: Date
    var isRead: Bool
}
