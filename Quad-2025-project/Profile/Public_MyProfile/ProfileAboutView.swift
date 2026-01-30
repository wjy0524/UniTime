//
//  ProfileAboutView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI

struct ProfileAboutView: View {
    let bio: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("About")
                .font(.headline.bold())
                .foregroundColor(.primary)

            if bio.isEmpty {
                Text("No bio added yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
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
