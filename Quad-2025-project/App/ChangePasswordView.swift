//
//  ChangePasswordView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {

    @State private var email = ""
    @State private var isSending = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 24) {

            Text("We'll send a password reset link to your email.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)

            Button {
                sendResetEmail()
            } label: {
                HStack {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSending ? "Sending..." : "Send Reset Email")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    email.isEmpty ? Color.gray : Color("UTAustinOrange")
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isSending || email.isEmpty)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            email = Auth.auth().currentUser?.email ?? ""
        }
        .alert("Password Reset", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    private func sendResetEmail() {
        guard email.contains("@") else {
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }

        isSending = true

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                isSending = false
                if let error = error {
                    alertMessage = error.localizedDescription
                } else {
                    alertMessage = "A password reset link has been sent to your email."
                }
                showAlert = true
            }
        }
    }
}
