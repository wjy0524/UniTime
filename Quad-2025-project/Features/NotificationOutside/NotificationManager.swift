//
//  NotificationManager.swift
//  Quad-2025-project
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // 🔔 권한 요청 (이미 AppDelegate에서도 하고 있지만 유지해도 OK)
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification denied")
            }
        }
    }

    // 🔔 이벤트 알림 예약
    func scheduleNotification(for event: Event) {
        // 🔔 reminder 없으면 알림 안 만듦
        print("🧪 scheduleNotification called")
        print("🧪 reminderMinutes:", event.reminderMinutes as Any)

        guard let minutes = event.reminderMinutes else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts in \(minutes) minutes"
        content.sound = .default

        // ✅ reminderMinutes 반영
        let triggerDate = event.date.addingTimeInterval(TimeInterval(-minutes * 60))
        guard triggerDate > Date() else {
            print("⏭️ Notification skipped (time already passed)")
            return
        }

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        // 🔑 이벤트 ID 기반 identifier
        let identifier = "event_\(event.id ?? UUID().uuidString)"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
        print("🔔 Notification scheduled:", identifier, triggerDate)
    }


    // 🔕 이벤트 알림 제거 (삭제 / 수정 시 사용)
    func removeNotification(for event: Event) {
        guard let id = event.id else { return }

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["event_\(id)"]
            )
    }
    
    // 🔔 NEW: 인앱 알림용 즉시 시스템 알림
        func scheduleImmediateNotification(
            identifier: String,
            title: String,
            body: String
        ) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            // 즉시 발동
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 1,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
            print("🔔 Immediate notification scheduled:", identifier)
        }
}

