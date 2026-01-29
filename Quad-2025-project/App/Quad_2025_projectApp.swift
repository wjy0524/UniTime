//
//  Quad_2025_projectApp.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/8/25.
//

import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()

        // 🔥 Push Notification Permission 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("🔔 Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
        }

        return true
    }
}

@main
struct Quad_2025_projectApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // 🔥 글로벌 ViewModel 들
    @StateObject var gpaVM = GPAViewModel()
    @StateObject var eventVM = EventViewModel()   // ⬅️ 새로 추가
    @AppStorage("forceDarkMode") private var forceDarkMode = false

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(forceDarkMode ? .dark : .light)
                .environmentObject(gpaVM)
                .environmentObject(eventVM)   // ⬅️ 캘린더 전체 공유
        }
    }
}

