//
//  FriendModels.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/23/26.
//

import Foundation
import FirebaseFirestore

struct Friend: Identifiable {
    var id: String { uid }

    let uid: String
    let username: String
    let profileImageURL: String?
}
