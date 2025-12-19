//
//  StudySession.swift
//  Quad-2025-project
//
//  Study session model for tracking study time
//

import FirebaseFirestore
import Foundation

struct StudySession: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval  // in seconds
    var isActive: Bool
    var blockedApps: [String]  // Bundle identifiers of blocked apps
    var date: Date  // Date for grouping sessions

    var durationInMinutes: Double {
        return duration / 60.0
    }

    var durationInHours: Double {
        return duration / 3600.0
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case startTime
        case endTime
        case duration
        case isActive
        case blockedApps
        case date
    }
}

// Weekly study data for chart
struct WeeklyStudyData: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
    let date: Date
}

// App blocking configuration
struct BlockedApp: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var bundleIdentifier: String
    var isBlocked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bundleIdentifier
        case isBlocked
    }
}

// Common apps to block
extension BlockedApp {
    static let commonApps: [BlockedApp] = [
        BlockedApp(name: "Instagram", bundleIdentifier: "com.burbn.instagram", isBlocked: true),
        BlockedApp(name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically", isBlocked: true),
        BlockedApp(name: "Twitter/X", bundleIdentifier: "com.atebits.Tweetie2", isBlocked: true),
        BlockedApp(name: "Facebook", bundleIdentifier: "com.facebook.Facebook", isBlocked: true),
        BlockedApp(name: "Snapchat", bundleIdentifier: "com.toyopagroup.picaboo", isBlocked: true),
        BlockedApp(name: "YouTube", bundleIdentifier: "com.google.ios.youtube", isBlocked: true),
        BlockedApp(name: "Reddit", bundleIdentifier: "com.reddit.Reddit", isBlocked: true),
        BlockedApp(
            name: "Discord", bundleIdentifier: "com.hammerandchisel.discord", isBlocked: true),
        BlockedApp(name: "Twitch", bundleIdentifier: "tv.twitch", isBlocked: true),
        BlockedApp(name: "Netflix", bundleIdentifier: "com.netflix.Netflix", isBlocked: true),
        BlockedApp(name: "Spotify", bundleIdentifier: "com.spotify.client", isBlocked: false),
        BlockedApp(name: "Safari", bundleIdentifier: "com.apple.mobilesafari", isBlocked: false),
        BlockedApp(name: "Messages", bundleIdentifier: "com.apple.MobileSMS", isBlocked: false),
        BlockedApp(name: "Mail", bundleIdentifier: "com.apple.mobilemail", isBlocked: false),
    ]
}
