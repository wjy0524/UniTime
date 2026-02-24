//
//  CourseChat.swift
//

import FirebaseFirestore
import Foundation

struct CourseChat: Identifiable, Codable {
    @DocumentID var id: String?
    
    var courseCode: String
    var members: [String]
    
    var lastMessage: String?
    var lastMessageTime: Date?
    var lastSenderName: String?
    var lastSenderId: String?
    
    var createdAt: Date?
    var lastMessageIndex: Int?  // unread 계산용
}
