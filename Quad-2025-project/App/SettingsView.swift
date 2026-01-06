//
//  SettingsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import FirebaseAuth
import SwiftUI

struct SettingsView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("forceDarkMode") private var forceDarkMode = false

    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isProcessing = false

    var body: some View {
        List {

            // MARK: - Account
            Section("Account") {

                NavigationLink {
                    // 🔑 uid 기반으로 ProfileEditView 생성
                    if let uid = Auth.auth().currentUser?.uid {
                        ProfileEditView(
                            viewModel: ProfileViewModel(uid: uid)
                        )
                    }
                } label: {
                    Label("Edit Profile", systemImage: "person.crop.circle")
                }

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    Label("Change Password", systemImage: "key")
                }
            }

            // MARK: - Preferences
            Section("Preferences") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Push Notifications", systemImage: "bell")
                }

                Toggle(isOn: $forceDarkMode) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
            }

            // MARK: - Support
            Section("Support") {
                NavigationLink {
                    AboutAppView()
                } label: {
                    Label("About Quad", systemImage: "info.circle")
                }

                NavigationLink {
                    ReportIssueView()
                } label: {
                    Label("Report a Problem", systemImage: "exclamationmark.bubble")
                }
            }

            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
                .disabled(isProcessing)
            }

            // MARK: - Logout
            Section {
                Button {
                    showLogoutAlert = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
                .disabled(isProcessing)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Alerts
        .alert("Log Out?", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) { performLogout() }
            Button("Cancel", role: .cancel) {}
        }

        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { performDeleteAccount() }
            Button("Cancel", role: .cancel) {}
        }

        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions
    private func performLogout() {
        isProcessing = true
        do {
            try authManager.signOut()
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func performDeleteAccount() {
        isProcessing = true
        Task {
            do {
                try await authManager.deleteAccount()
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
