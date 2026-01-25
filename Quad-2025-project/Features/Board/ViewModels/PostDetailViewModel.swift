//
//  PostDetailViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var commentText = ""
    @Published var likeCount = 0
    @Published var didLike = false
    @Published var replyingTo: Comment? = nil
    @Published var authorName = ""

    let db = Firestore.firestore()
    var uid: String { Auth.auth().currentUser?.uid ?? "" }

    // MARK: - Load (🔥 핵심 수정)
    func load(post: Post) async {
        guard let postId = post.id else { return }

        // ✅ 항상 최신 post를 Firestore에서 다시 읽기
        do {
            let snap = try await db.collection("posts")
                .document(postId)
                .getDocument()

            if let freshPost = try? snap.data(as: Post.self) {
                self.likeCount = freshPost.likeCount
            } else {
                self.likeCount = post.likeCount
            }
        } catch {
            print("❌ Failed to reload post:", error)
            self.likeCount = post.likeCount
        }

        // 🔥 authorId → username
        if let username = await fetchUsername(uid: post.authorId) {
            self.authorName = username
        } else {
            self.authorName = post.authorId
        }

        await checkLiked(post)
        await loadComments(post)
    }

    // MARK: - Likes
    func checkLiked(_ post: Post) async {
        guard let id = post.id else { return }

        let doc = try? await db.collection("users")
            .document(uid)
            .collection("likes")
            .document(id)
            .getDocument()

        didLike = doc?.exists ?? false
    }

    func toggleLike(_ post: Post) async {
        guard let id = post.id else { return }

        if didLike {
            try? await db.collection("posts")
                .document(id)
                .updateData(["likeCount": FieldValue.increment(Int64(-1))])

            try? await db.collection("users")
                .document(uid)
                .collection("likes")
                .document(id)
                .delete()

            likeCount -= 1
        } else {
            try? await db.collection("posts")
                .document(id)
                .updateData(["likeCount": FieldValue.increment(Int64(1))])

            try? await db.collection("users")
                .document(uid)
                .collection("likes")
                .document(id)
                .setData([:])

            likeCount += 1

            // 🔔 좋아요 알림 (자기 글에는 안 가게 하려면 조건 추가 가능)
            let notificationVM = NotificationViewModel()
            notificationVM.sendPostLikeNotification(
                toUserId: post.authorId,
                postId: id
            )
        }

        didLike.toggle()

        // 🔥 Profile / Board에 좋아요 변경 알림
        NotificationCenter.default.post(
            name: .didUpdateLikes,
            object: nil
        )
    }

    // MARK: - Comments
    func loadComments(_ post: Post) async {
        guard let postId = post.id else { return }

        let snap = try? await db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp")
            .getDocuments()

        var loaded = snap?.documents.compactMap {
            try? $0.data(as: Comment.self)
        } ?? []

        // UID → username
        for i in 0..<loaded.count {
            let uid = loaded[i].authorId
            if let username = await fetchUsername(uid: uid) {
                loaded[i].authorId = username
            }
        }

        self.comments = loaded
    }

    func addComment(_ post: Post) async {
        guard !commentText.isEmpty,
              let postId = post.id else { return }

        let comment = Comment(
            authorId: uid,
            text: commentText,
            likeCount: 0,
            timestamp: Date(),
            replyTo: replyingTo?.id
        )

        try? await db.collection("posts")
            .document(postId)
            .collection("comments")
            .addDocument(from: comment)

        // ✅ commentCount 증가 (서버 기준)
        try? await db.collection("posts")
            .document(postId)
            .updateData([
                "commentCount": FieldValue.increment(Int64(1))
            ])

        let notificationVM = NotificationViewModel()
        if let parent = replyingTo {
            notificationVM.sendPostCommentNotification(
                toUserId: parent.authorId,
                postId: postId
            )
        } else {
            notificationVM.sendPostCommentNotification(
                toUserId: post.authorId,
                postId: postId
            )
        }

        commentText = ""
        replyingTo = nil
        await loadComments(post)
    }
    
    func likeComment(post: Post, comment: Comment) async {
            guard let postId = post.id,
                  let commentId = comment.id else { return }
            
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index].likeCount += 1
            }
            
            try? await db.collection("posts")
                .document(postId)
                .collection("comments")
                .document(commentId)
                .updateData([
                    "likeCount": FieldValue.increment(Int64(1))
                ])
        }

    // MARK: - Helper
    func fetchUsername(uid: String) async -> String? {
        do {
            let snap = try await db.collection("users")
                .document(uid)
                .getDocument()

            if let user = try? snap.data(as: QuadUser.self) {
                return user.username
            }
        } catch {
            print("❌ Username fetch error:", error)
        }
        return nil
    }
}
