//
//  SettingsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

//
//  SettingsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var notificationsEnabled = true
    @State private var darkMode = false
    
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
                        Label("Delete Account", systemImage: "trash")
                    }
                }
                
                // MARK: - Log Out
                Section {
                    Button {
                        showLogoutAlert = true
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Logout Alert
            .alert("Log Out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    try? Auth.auth().signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to log in again.")
            }
            
            // MARK: - Delete Alert
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? await Auth.auth().currentUser?.delete()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

