//
//  NotificationManager.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification denied")
            }
        }
    }

    func scheduleNotification(for event: Event) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts soon!"
        content.sound = .default

        let triggerDate = event.date.addingTimeInterval(-1800) // 30분 전
        guard triggerDate > Date() else { return }

        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
