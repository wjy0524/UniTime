//
//  AppLaunchViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/29/26.
//

import SwiftUI
import FirebaseAuth

enum AppLaunchState {
    case launching
    case ready
}

final class AppLaunchViewModel: ObservableObject {

    @Published var state: AppLaunchState = .launching

    private var minimumSplashTimePassed = false
    private var authChecked = false

    init() {
        startMinimumSplashTimer()
        checkAuthState()
    }

    // 최소 스플래시 체류 시간 (UX 핵심)
    private func startMinimumSplashTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.minimumSplashTimePassed = true
            self.tryFinishLaunch()
        }
    }

    // Firebase Auth 상태 확인
    private func checkAuthState() {
        _ = Auth.auth().addStateDidChangeListener { _, _ in
            self.authChecked = true
            self.tryFinishLaunch()
        }
    }

    private func tryFinishLaunch() {
        if minimumSplashTimePassed && authChecked {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.state = .ready
            }
        }
    }
}
