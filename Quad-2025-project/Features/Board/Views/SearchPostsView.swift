//
//  SearchPostsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import SwiftUI

struct SearchPostsView: View {
    @StateObject var vm = SearchPostsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 🔍 Search Bar (Reddit 스타일)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search posts", text: $vm.query)
                        .onSubmit {
                            Task { await vm.search() }
                        }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()

                // Results
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.results) { post in
                            NavigationLink {
                                PostDetailView(post: post)
                            } label: {
                                searchResultCard(post)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Search")
        }
    }
}

func searchResultCard(_ post: Post) -> some View {
    VStack(alignment: .leading, spacing: 8) {

        HStack {
            Text(post.category.uppercased())
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color("UTAustinOrange").opacity(0.2))
                .cornerRadius(6)

            Spacer()
        }

        Text(post.title)
            .font(.headline)
            .lineLimit(2)

        Text(post.content)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)

        HStack(spacing: 16) {
            Label("\(post.likeCount)", systemImage: "heart")
            Label("\(post.commentCount)", systemImage: "bubble.right")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(14)
    .shadow(color: .black.opacity(0.05), radius: 4)
}
