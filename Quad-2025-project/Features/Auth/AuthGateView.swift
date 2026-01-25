//
//  AuthGateView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/8/25.
//

import FirebaseAuth
import SwiftUI

struct AuthGateView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showLogin = false

    var body: some View {
        Group {
            // 로그인 되어 있으면 메인 화면
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)

            // 로그인 안 되어 있으면 로그인 화면
            } else if showLogin {
                AuthView(
                    isLoggedIn: Binding(
                        get: { authManager.isAuthenticated },
                        set: { _ in }
                    )
                )
                .environmentObject(authManager)

            // 앱 시작 시 잠깐 보여주는 로딩 화면
            } else {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Checking authentication...")
                            .foregroundColor(.secondary)
                    }
                }
                .onAppear {
                    // 핵심: 무조건 로그인 화면으로 전환
                    DispatchQueue.main.async {
                        showLogin = true
                    }
                }
            }
        }
    }
}
