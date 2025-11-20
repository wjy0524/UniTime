//
//  Comment.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?

    var authorId: String
    var text: String
    var likeCount: Int
    var timestamp: Date

    var replyTo: String?   // 🔥 부모 댓글 ID (nil이면 1차 댓글)
}
