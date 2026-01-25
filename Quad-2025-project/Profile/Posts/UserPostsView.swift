//
//  UserPostsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
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
                    NavigationLink {
                        PostDetailView(post: post)
                    } label: {
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
                    .buttonStyle(.plain) // 🔥 이거 중요 (터치 영역/스타일 문제 방지)
                }
            }
            .padding(.horizontal)
            .task {
                await viewModel.fetchUserPosts(for: viewModel.targetUid)
            }
        }
    }
}
