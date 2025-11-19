//
//  UserPostsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

//
//  UserPostsView.swift
//

import SwiftUI

struct UserPostsView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {

        if viewModel.userPosts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .padding(.top, 40)
                    .foregroundColor(.gray)

                Text("No posts yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)

        } else {
            VStack(spacing: 16) {
                ForEach(viewModel.userPosts) { post in
                    VStack(alignment: .leading, spacing: 8) {

                        Text(post.title)
                            .font(.headline)

                        Text(post.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
                }
            }
            .padding(.horizontal)
            // Load posts ONCE
            .task {
                await viewModel.fetchUserPosts()
            }
        }
    }
}
