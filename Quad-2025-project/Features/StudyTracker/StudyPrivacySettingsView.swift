//
//  StudyPrivacySettingsView.swift
//  Quad-2025-project
//
//  Privacy settings for controlling study status visibility to friends
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct StudyPrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var shareStudyStatus: Bool = true
    @State private var isLoading: Bool = true
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $shareStudyStatus) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share Study Status")
                                .font(.headline)
                            Text("Allow friends to see when you're studying and your study time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(Color("UTAustinOrange"))
                } header: {
                    Text("Privacy")
                } footer: {
                    Text(
                        "When enabled, your friends can see your real-time study sessions and total study time. When disabled, your study activity is completely private."
                    )
                    .font(.caption)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: shareStudyStatus ? "eye.fill" : "eye.slash.fill")
                                .font(.title2)
                                .foregroundColor(shareStudyStatus ? .green : .red)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(shareStudyStatus ? "Visible to Friends" : "Private")
                                    .font(.headline)
                                Text(
                                    shareStudyStatus
                                        ? "Friends can see your study activity"
                                        : "Your study activity is hidden"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("What friends can see:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            PrivacyInfoRow(
                                icon: "circle.fill",
                                text: "When you're currently studying",
                                isVisible: shareStudyStatus
                            )

                            PrivacyInfoRow(
                                icon: "clock.fill",
                                text: "Your study session duration",
                                isVisible: shareStudyStatus
                            )

                            PrivacyInfoRow(
                                icon: "calendar",
                                text: "Total study time today and this week",
                                isVisible: shareStudyStatus
                            )
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Status Preview")
                }
            }
            .navigationTitle("Study Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveSettings()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Color("UTAustinOrange"))
                    }
                }
            }
            .disabled(isLoading || isSaving)
            .overlay {
                if isLoading {
                    ProgressView("Loading settings...")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 10)
                        )
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadSettings()
        }
    }

    // MARK: - Load Settings

    func loadSettings() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            isLoading = false
            return
        }

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Failed to load settings: \(error.localizedDescription)"
                showError = true
                isLoading = false
                return
            }

            if let data = snapshot?.data(),
                let share = data["shareStudyStatus"] as? Bool
            {
                shareStudyStatus = share
            }

            isLoading = false
        }
    }

    // MARK: - Save Settings

    func saveSettings() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }

        isSaving = true

        db.collection("users").document(userId).updateData([
            "shareStudyStatus": shareStudyStatus
        ]) { error in
            isSaving = false

            if let error = error {
                errorMessage = "Failed to save settings: \(error.localizedDescription)"
                showError = true
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Privacy Info Row

struct PrivacyInfoRow: View {
    let icon: String
    let text: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isVisible ? .green : .red)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Image(systemName: isVisible ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(isVisible ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StudyPrivacySettingsView()
}
