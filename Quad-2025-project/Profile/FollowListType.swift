//
//  FollowListType.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/7/26.
//

import Foundation

enum FollowListType {
    case followers
    case following

    var title: String {
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        }
    }
}
