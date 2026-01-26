//
//  QuadUser.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

//
//  QuadUser.swift
//

import FirebaseFirestore
import Foundation

struct QuadUser: Codable, Identifiable {
    @DocumentID var id: String?
    var uid: String

    var username: String?          // ✅ optional
    let username_lower: String?
    var major: String?
    var year: String?
    var email: String?
    var phone: String?
    var bio: String?
    var profileImageURL: String?
    var shareStudyStatus: Bool = true

    var displayName: String {
        username ?? "Unknown User"  // ✅ UI fallback
    }
}

