//
//  CourseChat.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import FirebaseFirestore
import Foundation

struct CourseChat: Identifiable, Codable {
    @DocumentID var id: String?
    var courseCode: String
    var members: [String]
    var createdAt: Date?
}
