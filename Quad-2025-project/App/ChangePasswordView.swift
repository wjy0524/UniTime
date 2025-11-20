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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your email to receive a password reset link.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Button {
                if !email.isEmpty {
                    FirebaseAuth.Auth.auth().sendPasswordReset(withEmail: email)
                }
            } label: {
                Text("Send Reset Email")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("UTAustinOrange"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 50)
        .navigationTitle("Change Password")
    }
}
