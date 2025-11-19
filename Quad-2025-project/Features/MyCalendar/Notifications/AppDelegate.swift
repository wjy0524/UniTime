//
//  AppDelegate.swift
//  미국 에타
//
//  Created by Isaac Choi on 9/15/25.
//

import UIKit
import UserNotifications

class AppDelegate2: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
        }

        // delegate 지정
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 앱이 켜져 있을 때 알림이 오면 배너 + 소리로 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    private func scheduleNotification(for event: EventModel) {
        guard let minutes = event.reminderMinutesBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts soon" + (event.location != nil ? " at \(event.location!)" : "")
        content.sound = .default

        let triggerDate = event.startDate.addingTimeInterval(TimeInterval(-minutes * 60))
        if triggerDate < Date() { return }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: triggerDate.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            } else {
                print("Notification scheduled for \(triggerDate)")
                
                // ✅ 예약된 알림 확인
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    for req in requests {
                        print("Pending notification: \(req.identifier), trigger = \(String(describing: req.trigger))")
                    }
                }
            }
        }
    }
}
