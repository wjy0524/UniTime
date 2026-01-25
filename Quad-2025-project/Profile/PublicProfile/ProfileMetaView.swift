//
//  ProfileMetaView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI

struct ProfileMetaView: View {
    let major: String
    let grade: String
    let email: String
    let phone: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: - Title
            Text("Info")
                .font(.headline.bold())
                .foregroundColor(.primary)

            // MARK: - Major & Year
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Major")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(major.isEmpty ? "-" : major)
                        .font(.body)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Year")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(grade.isEmpty ? "-" : grade)
                        .font(.body)
                }

                Spacer()
            }

            Divider()
                .background(Color.secondary.opacity(0.2))

            // MARK: - Contact Info
            VStack(alignment: .leading, spacing: 10) {
                Text("Contact")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(Color("UTAustinOrange"))
                    Text(email.isEmpty ? "-" : email)
                }
                .font(.subheadline)

                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.green)
                    Text(phone.isEmpty ? "-" : phone)
                }
                .font(.subheadline)
            }

        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal)
        .padding(.top, 10)
    }
}
