//
//  PostDetailView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import SwiftUI
import Kingfisher

struct PostDetailView: View {
    let post: Post

    @StateObject var vm = PostDetailViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Title
                Text(post.title)
                    .font(.title2.bold())
                    .padding(.top, 10)

                // MARK: - Author + Timestamp
                HStack {
                    Text("by \(vm.authorName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(post.timestamp.formatted())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // MARK: - Images Carousel
                if !post.images.isEmpty {
                    TabView {
                        ForEach(post.images, id: \.self) { url in
                            KFImage(URL(string: url))
                                .resizable()
                                .scaledToFill()
                                .frame(height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .clipped()
                        }
                    }
                    .frame(height: 260)
                    .tabViewStyle(.page)
                }

                // MARK: - Content
                Text(post.content)
                    .font(.body)
                    .padding(.top, 4)

                // MARK: - Likes / Comments Count
                HStack(spacing: 20) {
                    HStack {
                        Image(systemName: vm.didLike ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                        Text("\(vm.likeCount)")
                    }
                    .onTapGesture {
                        Task { await vm.toggleLike(post) }
                    }

                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.commentCount)")
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 4)

                Divider()

                // MARK: - Comments Section
                commentsSection
            }
            .padding(.horizontal)
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load(post: post)
        }
        .safeAreaInset(edge: .bottom) {
            commentInputBar
        }
    }
}

extension PostDetailView {

    // MARK: - Comments Section
    @ViewBuilder
    var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Comments")
                .font(.headline)

            if vm.comments.isEmpty {
                VStack {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)
                        .padding(.top, 30)

                    Text("No comments yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

            } else {
                ForEach(topLevelComments) { comment in
                    commentView(comment: comment)
                }
            }
        }
        .padding(.bottom, 80)
    }

    // MARK: - Build Comment Tree
    var topLevelComments: [Comment] {
        vm.comments.filter { $0.replyTo == nil }
    }

    func replies(for parent: Comment) -> [Comment] {
        vm.comments.filter { $0.replyTo == parent.id }
    }

    // MARK: - Comment Cell
    @ViewBuilder
    func commentView(comment: Comment) -> AnyView {

        AnyView(
            VStack(alignment: .leading, spacing: 6) {

                // First row
                HStack {
                    Text(comment.authorId)
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()

                    Text(comment.timestamp.formatted())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Text
                Text(comment.text)
                    .font(.body)

                // Buttons
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("\(comment.likeCount)")
                    }
                    .onTapGesture {
                        Task { await vm.likeComment(post: post, comment: comment) }
                    }

                    Text("Reply")
                        .font(.caption)
                        .foregroundColor(Color("UTAustinOrange"))
                        .onTapGesture {
                            vm.replyingTo = comment
                        }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // Replies
                let repliesList = replies(for: comment)

                if !repliesList.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {

                        ForEach(repliesList) { reply in
                            HStack(alignment: .top, spacing: 10) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    commentView(comment: reply)  // 🔥 recursive allowed now
                                }
                            }
                        }
                    }
                    .padding(.leading, 20)
                }
            }
            .padding(.vertical, 8)
        )
    }

}

extension PostDetailView {

    // MARK: - Bottom Comment Input Bar
    var commentInputBar: some View {
        VStack(spacing: 0) {

            Divider()

            HStack(alignment: .center, spacing: 12) {

                if let replyTarget = vm.replyingTo {
                    HStack {
                        Text("Replying to \(replyTarget.authorId)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Cancel") {
                            vm.replyingTo = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }

                TextField("Add a comment...", text: $vm.commentText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await vm.addComment(post) }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color("UTAustinOrange"))
                }
            }
            .padding(12)
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
        }
    }
}
