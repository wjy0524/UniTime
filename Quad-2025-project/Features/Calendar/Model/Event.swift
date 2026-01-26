//
//  Event.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var title: String
    var date: Date
    var type: String
    var location: String
    var colorHex: String
    var sharedWith: [String]
    var reminderMinutes: Int?   // 🔔

    init(
        id: String? = nil,
        ownerId: String,
        title: String,
        date: Date,
        type: String = "General",
        location: String = "",
        colorHex: String = "#FF6A00",
        sharedWith: [String] = [],
        reminderMinutes: Int? = nil   // ✅ 추가
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.date = date
        self.type = type
        self.location = location
        self.colorHex = colorHex
        self.sharedWith = sharedWith
        self.reminderMinutes = reminderMinutes
    }
}
