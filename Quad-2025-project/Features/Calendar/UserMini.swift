//
//  UserMini.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

struct UserMini: Identifiable, Codable {
    var id: String { uid }
    let uid: String
    let username: String
    let profileImageURL: String
}
