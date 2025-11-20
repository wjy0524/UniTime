//
//  QuadUser.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

//
//  QuadUser.swift
//

import Foundation
import FirebaseFirestore

struct QuadUser: Codable, Identifiable {
    @DocumentID var id: String?  // Firestore doc ID
    var uid: String

    var username: String
    let username_lower: String
    var major: String
    var year: String
    var email: String
    var phone: String
    var bio: String
    var profileImageURL: String

    var identifier: String { id ?? uid }
    
    

}
