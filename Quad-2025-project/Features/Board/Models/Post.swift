//
//  Post.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {
    @DocumentID var id: String?
    var authorId: String
    var title: String
    var content: String
    var timestamp: Date

    var images: [String] = []        // 🔥 추가
    var category: String = "general" // 🔥 게시판 카테고리
    var likeCount: Int = 0           // 좋아요 수
    var commentCount: Int = 0        // 댓글 수
    var keywords: [String] = []

}
