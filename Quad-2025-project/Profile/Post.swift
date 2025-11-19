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
}
