//
//  AuthGateView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/8/25.
//

import FirebaseAuth
import LocalAuthentication
import SwiftUI

struct AuthGateView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showLogin = false
    @State private var isCheckingBiometrics = false

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else if showLogin {
                AuthView(
                    isLoggedIn: Binding(
                        get: { authManager.isAuthenticated },
                        set: { _ in }
                    )
                )
                .environmentObject(authManager)
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
                    authenticateWithBiometrics()
                }
            }
        }
    }

    func authenticateWithBiometrics() {
        guard !isCheckingBiometrics else { return }
        isCheckingBiometrics = true

        // Check if user is already authenticated
        authManager.checkAuthStatus()

        if Auth.auth().currentUser != nil {
            // Firebase session exists, try biometric authentication
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Login with Face ID"
                ) { success, authError in
                    DispatchQueue.main.async {
                        isCheckingBiometrics = false
                        if success {
                            authManager.checkAuthStatus()
                        } else {
                            showLogin = true
                        }
                    }
                }
            } else {
                // Biometrics not available, show login
                isCheckingBiometrics = false
                showLogin = true
            }
        } else {
            // No session, show login screen
            isCheckingBiometrics = false
            showLogin = true
        }
    }
}
