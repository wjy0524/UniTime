//
//  EventShareRequest.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/25/26.
//

import FirebaseFirestore
import Foundation

struct EventShareRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let eventId: String
    let fromUid: String
    let toUid: String
    let status: String          // "pending" | "accepted" | "declined"
    let createdAt: Timestamp
}
