//
//  AppConstants.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/13/26.
//

import SwiftUI

enum AppConstants {
    
    // MARK: - Layout
    enum Layout {
        static let logoSize: CGFloat = 130
        static let avatarSizeLarge: CGFloat = 110
        static let avatarSizeMedium: CGFloat = 80
        static let avatarSizeSmall: CGFloat = 50
        static let avatarSizeTiny: CGFloat = 44
        
        static let cornerRadiusLarge: CGFloat = 20
        static let cornerRadiusMedium: CGFloat = 16
        static let cornerRadiusSmall: CGFloat = 12
        static let cornerRadiusTiny: CGFloat = 8
        
        static let paddingLarge: CGFloat = 24
        static let paddingMedium: CGFloat = 16
        static let paddingSmall: CGFloat = 12
        static let paddingTiny: CGFloat = 8
        
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: CGFloat = 0.1
    }
    
    // MARK: - Animation
    enum Animation {
        static let defaultDuration: Double = 0.4
        static let quickDuration: Double = 0.2
        static let slowDuration: Double = 0.6
        static let splashMinimumDelay: Double = 1.8
    }
    
    // MARK: - Limits
    enum Limits {
        static let maxImageUploadSize: Int = 5_000_000 // 5MB
        static let maxImagesPerPost: Int = 5
        static let maxCommentLength: Int = 500
        static let maxPostTitleLength: Int = 100
        static let maxPostContentLength: Int = 5000
        static let maxBioLength: Int = 150
    }
    
    // MARK: - Firebase
    enum Firebase {
        static let postsPerPage: Int = 20
        static let messagesPerPage: Int = 50
        static let maxQueryLimit: Int = 100
    }
    
    // MARK: - Colors
    enum Colors {
        static let primaryOrange = "UTAustinOrange"
        static let accentColor = "UTAustinOrange"
    }
    
    // MARK: - Strings
    enum Strings {
        static let appName = "UniTime"
        static let defaultErrorMessage = "An error occurred. Please try again."
        static let networkErrorMessage = "Network error. Please check your connection."
        static let authErrorMessage = "Authentication error. Please sign in again."
    }
}
