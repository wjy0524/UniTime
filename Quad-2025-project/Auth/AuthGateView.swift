//
//  AuthGateView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/8/25.
//

import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct AuthGateView: View {
    @State private var isLoggedIn = false
    @State private var showLogin = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                HomeView()   // ✅ 로그인 성공 → 메인 페이지
            } else if showLogin {
                AuthView(isLoggedIn: $isLoggedIn)  // ✅ 로그인/회원가입 UI
            } else {
                Text("Checking authentication...")
                    .onAppear {
                        authenticateWithBiometrics()
                    }
            }
        }
    }
    
    func authenticateWithBiometrics() {
        if let _ = Auth.auth().currentUser {
            // ✅ Firebase 세션 있으면 Face ID / Touch ID 실행
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                       localizedReason: "Login with Face ID") { success, authError in
                    DispatchQueue.main.async {
                        if success {
                            isLoggedIn = true
                        } else {
                            showLogin = true
                        }
                    }
                }
            } else {
                showLogin = true
            }
        } else {
            // ✅ 세션 없으면 → 로그인 화면
            showLogin = true
        }
    }
}
