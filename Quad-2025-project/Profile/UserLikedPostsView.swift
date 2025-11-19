//
//  UserLikedPostsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//
import SwiftUI

struct UserLikedPostsView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {

        if viewModel.likedPosts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "heart.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .padding(.top, 40)

                Text("No liked posts yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)

        } else {
            VStack(spacing: 16) {
                ForEach(viewModel.likedPosts) { post in
                    HStack(spacing: 12) {

                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.title)
                                .font(.headline)

                            Text(post.content)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
                }
            }
            .padding(.horizontal)
            // Firestore를 1번만 호출
            .task {
                await viewModel.fetchLikedPosts()
            }
        }
    }
}
