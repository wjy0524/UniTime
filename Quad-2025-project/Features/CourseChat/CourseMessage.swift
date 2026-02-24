//
//  CourseMessage.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
import FirebaseFirestore
import Foundation

struct CourseMessage: Identifiable, Codable {

    @DocumentID var documentId: String?

    var senderId: String
    var senderName: String?
    var text: String

    // ✅ 비옵셔널로 고정
    var timestamp: Date

    var messageIndex: Int

    // Reply
    var replyToMessageId: String?
    var replyToText: String?
    var replyToSenderName: String?

    // SwiftUI용
    var id: Int { messageIndex }

    // ✅ 디코딩 안정화: 필드 누락/서버타임스탬프 지연 대비
    enum CodingKeys: String, CodingKey {
        case documentId
        case senderId, senderName, text
        case timestamp
        case messageIndex
        case replyToMessageId, replyToText, replyToSenderName
    }

    init(
        documentId: String? = nil,
        senderId: String,
        senderName: String? = nil,
        text: String,
        timestamp: Date = Date(),
        messageIndex: Int,
        replyToMessageId: String? = nil,
        replyToText: String? = nil,
        replyToSenderName: String? = nil
    ) {
        self.documentId = documentId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.messageIndex = messageIndex
        self.replyToMessageId = replyToMessageId
        self.replyToText = replyToText
        self.replyToSenderName = replyToSenderName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        documentId = try? c.decode(String.self, forKey: .documentId)
        senderId = try c.decode(String.self, forKey: .senderId)
        senderName = try? c.decode(String.self, forKey: .senderName)
        text = try c.decode(String.self, forKey: .text)

        // ✅ Firestore Timestamp/Date 모두 대응 + 누락이면 Date()
        if let ts = try? c.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = ts.dateValue()
        } else if let d = try? c.decode(Date.self, forKey: .timestamp) {
            timestamp = d
        } else {
            timestamp = Date()
        }

        messageIndex = (try? c.decode(Int.self, forKey: .messageIndex)) ?? 0
        replyToMessageId = try? c.decode(String.self, forKey: .replyToMessageId)
        replyToText = try? c.decode(String.self, forKey: .replyToText)
        replyToSenderName = try? c.decode(String.self, forKey: .replyToSenderName)
    }
}
