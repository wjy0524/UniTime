//
//  AuthenticationManager.swift
//  Quad-2025-project
//
//  Created on Auth Feature Enhancement
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        registerAuthStateHandler()
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    // MARK: - Auth State Listener

    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noUser
        }

        try await user.delete()
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - Check Auth Status

    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            currentUser = user
            isAuthenticated = true
        } else {
            currentUser = nil
            isAuthenticated = false
        }
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case noUser
    case signOutFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No user is currently signed in"
        case .signOutFailed:
            return "Failed to sign out"
        case .deleteFailed:
            return "Failed to delete account"
        }
    }
}
