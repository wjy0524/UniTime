//
//  Quad_2025_projectApp.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/8/25.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct Quad_2025_projectApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
  @StateObject var gpaVM = GPAViewModel()   // 🔥 하나만 생성

  var body: some Scene {
    WindowGroup {
        SplashView()  //이미
            .environmentObject(gpaVM)   // 🔥 모든 화면에 공유
    }
  }
}
