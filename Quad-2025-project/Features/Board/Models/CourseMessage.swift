//
//  CourseMessage.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import FirebaseFirestore
import Foundation

struct CourseMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String?
    var text: String
    var timestamp: Date
}
