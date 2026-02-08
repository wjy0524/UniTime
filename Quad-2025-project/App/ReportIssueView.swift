//
//  ReportIssueView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ReportIssueView: View {

    @State private var message = ""
    @State private var isSending = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // 🧠 Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Report a Problem")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Let us know if something isn’t working as expected. Your feedback helps us improve UniTime.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 📝 Input Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Describe the issue")
                        .font(.headline)

                    TextEditor(text: $message)
                        .frame(height: 160)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4))
                        )

                    Text("Please include as much detail as possible.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)

                // 🚀 Submit Button
                Button {
                    submitReport()
                } label: {
                    HStack {
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSending ? "Sending..." : "Submit Report")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray
                        : Color("UTAustinOrange")
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(isSending || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)

        // ✅ Alerts
        .alert("Thank you!", isPresented: $showSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("Your report has been successfully submitted.")
        }

        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Firestore
    private func submitReport() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true

        let data: [String: Any] = [
            "uid": Auth.auth().currentUser?.uid ?? "anonymous",
            "message": trimmed,
            "status": "new",
            "createdAt": Timestamp()
        ]

        Firestore.firestore()
            .collection("reports")
            .addDocument(data: data) { error in
                DispatchQueue.main.async {
                    isSending = false
                    if let error = error {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    } else {
                        showSuccessAlert = true
                        message = ""
                    }
                }
            }
    }
}
