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

    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var notificationsEnabled = true
    @State private var darkMode = false
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Account Section
                Section(header: Text("Account")) {
                    NavigationLink {
                        ProfileEditView(viewModel: ProfileViewModel())
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
                Section(header: Text("Preferences")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Push Notifications", systemImage: "bell.badge")
                    }

                    Toggle(isOn: $darkMode) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                }

                // MARK: - Support
                Section(header: Text("Support")) {
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
                        HStack {
                            Label("Delete Account", systemImage: "trash")
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isProcessing)
                }

                // MARK: - Log Out
                Section {
                    Button {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isProcessing)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)

            // MARK: - Logout Alert
            .alert("Log Out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    performLogout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to log in again.")
            }

            // MARK: - Delete Alert
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    performDeleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }

            // MARK: - Error Alert
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Helper Functions

    private func performLogout() {
        isProcessing = true

        do {
            try authManager.signOut()
            // No need to dismiss - AuthGateView will automatically show login screen
            // when authManager.isAuthenticated becomes false
        } catch {
            isProcessing = false
            errorMessage = "Failed to log out: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func performDeleteAccount() {
        isProcessing = true

        Task {
            do {
                try await authManager.deleteAccount()
                // AuthGateView will automatically show login screen
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage =
                        "Failed to delete account: \(error.localizedDescription)\n\nYou may need to re-authenticate to delete your account."
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthenticationManager())
    }
}
